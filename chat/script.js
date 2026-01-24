// Configuração
const WEBHOOK_URL = "http://localhost:5678/webhook/e694bea8-397d-4953-835d-734a7893defc/chat";

// Elementos do DOM
const chatHistory = document.getElementById('chat-history');
const chatInput = document.getElementById('chat-input');
const sendBtn = document.getElementById('send-btn');
const clearBtn = document.getElementById('clear-btn');
const stopBtn = document.getElementById('stop-btn');

let currentAbortController = null; // Para cancelar requisições

// Ícones SVG
const BOT_ICON_SVG = `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"></rect><circle cx="12" cy="5" r="2"></circle><path d="M12 7v4"></path><line x1="8" y1="16" x2="8" y2="16"></line><line x1="16" y1="16" x2="16" y2="16"></line></svg>`;
const USER_ICON_SVG = `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>`;

console.log('Script carregado. Elementos encontrados:', { chatHistory, chatInput, sendBtn, clearBtn, stopBtn });

// Função auxiliar para gerar UUID
function generateUUID() {
    if (typeof crypto !== 'undefined' && crypto.randomUUID) {
        return crypto.randomUUID();
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Inicializar Mensagem de Boas-vindas se estiver vazio (após reload manual que não limpa HTML estático)
// Na verdade, o HTML estático já tem uma msg, mas sem ícone. Vamos limpar e refazer ou ajustar.
// Como o HTML é estático, melhor limpar no JS e recriar com ícone se for a primeira vez.
if (chatHistory.children.length > 0 && !chatHistory.innerHTML.includes('message-icon')) {
    // Substitui a msg estática inicial pela dinâmica com ícone
    chatHistory.innerHTML = '';
    addMessageToUI('Olá! Como posso ajudar você hoje?', 'bot');
}

// Gerenciamento de Sessão
let sessionId = localStorage.getItem('n8n_chat_session_id');
if (!sessionId) {
    sessionId = generateUUID();
    localStorage.setItem('n8n_chat_session_id', sessionId);
}
console.log('Session ID:', sessionId);

// Ajustar altura do textarea automaticamente
chatInput.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
    if (this.value === '') this.style.height = 'auto';
});

// Enviar com Enter
chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

sendBtn.addEventListener('click', sendMessage);

// Ação do Botão Parar
stopBtn.addEventListener('click', () => {
    if (currentAbortController) {
        currentAbortController.abort();
        currentAbortController = null;
        console.log('Geração interrompida pelo usuário.');
        finishGeneration(true); // true = foi abortado
    }
});

clearBtn.addEventListener('click', () => {
    if(confirm('Deseja iniciar uma nova conversa? O histórico será limpo.')) {
        sessionId = generateUUID();
        localStorage.setItem('n8n_chat_session_id', sessionId);
        chatHistory.innerHTML = '';
        addMessageToUI('Conversa reiniciada. Como posso ajudar?', 'bot');
    }
});

async function sendMessage() {
    const text = chatInput.value.trim();
    if (!text) return;

    // Reset UI state
    addMessageToUI(text, 'user');
    chatInput.value = '';
    chatInput.style.height = 'auto';
    sendBtn.disabled = true;
    
    // Mostra botão de parar
    stopBtn.classList.add('visible');

    // Cria bolha com indicador de loading (Imagem SVG)
    const loadingHtml = `<img src="loader.svg" alt="Digitando..." class="loading-gif">`;
    const botMessageContent = addMessageToUI(null, 'bot', true);
    botMessageContent.innerHTML = loadingHtml; // Inicia com loading
    
    let isFirstContent = true;
    currentAbortController = new AbortController();
    const signal = currentAbortController.signal;

    try {
        console.log('Iniciando fetch para:', WEBHOOK_URL);
        
        const response = await fetch(WEBHOOK_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                sessionId: sessionId,
                action: "sendMessage",
                chatInput: text
            }),
            signal: signal
        });

        if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

        console.log('Conexão estabelecida, aguardando stream...');

        const reader = response.body.getReader();
        const decoder = new TextDecoder("utf-8");
        let buffer = "";
        let isFirstContent = true; // Controla quando remover o loading visualmente

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            buffer += chunk;

            let lines = buffer.split('\n');
            buffer = lines.pop(); 

            for (const line of lines) {
                if (line.trim()) {
                    // Se processJSONLine retornar true, significa que adicionou texto
                    if (processJSONLine(line, botMessageContent, isFirstContent)) {
                        isFirstContent = false; // Já limpamos o loading, não precisa mais
                    }
                }
            }
        }
        
        if (buffer.trim()) {
             processJSONLine(buffer, botMessageContent, isFirstContent);
        }

        finishGeneration(false);

    } catch (error) {
        if (error.name === 'AbortError') {
            // Tratado no click do botão
        } else {
            console.error('Erro no envio:', error);
            // Se der erro e ainda estiver com loading, limpa
            if (botMessageContent.querySelector('.loading-gif')) {
                botMessageContent.innerHTML = "";
            }
            
            botMessageContent.innerText += `\n[Erro: ${error.message}]`;
            
            if (error.message.includes('Failed to fetch') || error.name === 'TypeError') {
                 botMessageContent.innerText += "\n(Possível erro de CORS ou servidor offline)";
            }
            finishGeneration(false);
        }
    }
}

function finishGeneration(aborted) {
    sendBtn.disabled = false;
    stopBtn.classList.remove('visible');
    currentAbortController = null;
    
    if (aborted) {
        const lastMsg = chatHistory.querySelector('.bot-message:last-child .message-content');
        if(lastMsg) {
             const stopIndicator = document.createElement('span');
             stopIndicator.style.color = '#999';
             stopIndicator.style.fontSize = '0.8em';
             stopIndicator.innerText = ' (interrompido)';
             lastMsg.appendChild(stopIndicator);
        }
    }
    scrollToBottom();
}

function processJSONLine(jsonStr, element, shouldClearLoading) {
    try {
        const data = JSON.parse(jsonStr);
        if (data.type === 'item' && data.content) {
            // Se for o primeiro conteúdo e tivermos que limpar o loading:
            if (shouldClearLoading) {
                // Remove apenas a imagem de loading, mantém qualquer texto anterior (se houver, embora improvável aqui)
                const loader = element.querySelector('.loading-gif');
                if (loader) loader.remove();
            }
            element.innerText += data.content;
            scrollToBottom();
            return true; // Indicamos que adicionamos conteúdo
        }
    } catch (e) {
        console.warn("Erro ao fazer parse de trecho JSON:", e);
    }
    return false;
}

function addMessageToUI(text, sender, returnElement = false) {
    const msgDiv = document.createElement('div');
    msgDiv.classList.add('message', `${sender}-message`);
    
    // Criar Ícone
    const iconDiv = document.createElement('div');
    iconDiv.classList.add('message-icon');
    iconDiv.innerHTML = sender === 'bot' ? BOT_ICON_SVG : USER_ICON_SVG;

    // Criar Conteúdo
    const contentDiv = document.createElement('div');
    contentDiv.classList.add('message-content');
    
    if (text !== null) {
        contentDiv.innerText = text;
    }
    
    // Montar (O CSS row/row-reverse cuida da ordem visual)
    msgDiv.appendChild(iconDiv);
    msgDiv.appendChild(contentDiv);
    
    chatHistory.appendChild(msgDiv);
    scrollToBottom();

    if (returnElement) return contentDiv;
}

function scrollToBottom() {
    chatHistory.scrollTop = chatHistory.scrollHeight;
}