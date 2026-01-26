// Configuração
const chat_id = 'e694bea8-397d-4953-835d-734a7893defc';
let WEBHOOK_URL = `http://localhost:5678/webhook/${chat_id}/chat`;

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

// Inicializar interface (substitui msg estática por dinâmica com ícone)
if (chatHistory.children.length > 0 && !chatHistory.innerHTML.includes('message-icon')) {
    chatHistory.innerHTML = '';
    addMessageToUI('Olá! Como posso ajudar você hoje?', 'bot');
}

// Gerenciamento de Sessão
let sessionId = localStorage.getItem('n8n_chat_session_id');
if (!sessionId) {
    sessionId = generateUUID();
    localStorage.setItem('n8n_chat_session_id', sessionId);
}

// Ajustar altura do textarea
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

stopBtn.addEventListener('click', () => {
    if (currentAbortController) {
        currentAbortController.abort();
        currentAbortController = null;
        finishGeneration(true);
    }
});

// Lógica de Limpeza Sincronizada com n8n
clearBtn.addEventListener('click', async () => {
    if(confirm('Deseja iniciar uma nova conversa? O histórico será limpo no servidor.')) {
        
        const oldBtnText = clearBtn.innerText;
        clearBtn.disabled = true;
        clearBtn.innerText = 'Limpando...';

        try {
            // Envia o comando de limpeza para o n8n usando o ID atual
            await fetch(WEBHOOK_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 
                    sessionId: sessionId, 
                    action: "clearSession" 
                })
            });
        } catch (error) {
            console.error('Erro ao solicitar limpeza ao n8n:', error);
        }

        // Reseta tudo localmente
        sessionId = generateUUID();
        localStorage.setItem('n8n_chat_session_id', sessionId);
        chatHistory.innerHTML = '';
        addMessageToUI('Conversa reiniciada. Como posso ajudar?', 'bot');
        
        clearBtn.disabled = false;
        clearBtn.innerText = oldBtnText;
    }
});

async function sendMessage() {
    const text = chatInput.value.trim();
    if (!text) return;

    addMessageToUI(text, 'user');
    chatInput.value = '';
    chatInput.style.height = 'auto';
    sendBtn.disabled = true;
    stopBtn.classList.add('visible');

    const botMessageContent = addMessageToUI(null, 'bot', true);
    botMessageContent.innerHTML = `<img src="loader.svg" alt="Digitando..." class="loading-gif">`;
    
    currentAbortController = new AbortController();
    const signal = currentAbortController.signal;

    let fullContent = "";

    try {
        const response = await fetch(WEBHOOK_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sessionId, action: "sendMessage", chatInput: text }),
            signal: signal
        });

        if (!response.ok) throw new Error(`Erro HTTP: ${response.status}`);

        const reader = response.body.getReader();
        const decoder = new TextDecoder("utf-8");
        let buffer = "";
        
        const loader = botMessageContent.querySelector('.loading-gif');
        if (loader) loader.remove();

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            buffer += chunk;

            const lines = buffer.split('\n');
            buffer = lines.pop(); 

            for (const line of lines) {
                if (line.trim()) {
                    try {
                        const data = JSON.parse(line);
                        if (data.type === 'item' && data.content) {
                            fullContent += data.content;
                            botMessageContent.innerText = fullContent; 
                            scrollToBottom();
                        }
                    } catch (e) {
                        // Ignora chunks incompletos
                    }
                }
            }
        }
        
        finishGeneration(false, botMessageContent, fullContent);

    } catch (error) {
        if (error.name === 'AbortError') {
             finishGeneration(true, botMessageContent, fullContent);
        } else {
            console.error('Erro no envio:', error);
            botMessageContent.innerText = fullContent + `\n\n[Erro: ${error.message}]`;
            finishGeneration(false, null, null);
        }
    }
}

function finishGeneration(aborted, element, markdownContent) {
    sendBtn.disabled = false;
    stopBtn.classList.remove('visible');
    currentAbortController = null;

    if (element && markdownContent) {
        element.innerHTML = marked.parse(markdownContent);
    }
    
    if (aborted && element) {
         const stopIndicator = document.createElement('span');
         stopIndicator.className = 'stop-indicator';
         stopIndicator.innerText = ' (interrompido)';
         element.appendChild(stopIndicator);
    }
    scrollToBottom();
}

function addMessageToUI(text, sender, returnElement = false) {
    const msgDiv = document.createElement('div');
    msgDiv.classList.add('message', `${sender}-message`);
    
    const iconDiv = document.createElement('div');
    iconDiv.classList.add('message-icon');
    iconDiv.innerHTML = sender === 'bot' ? BOT_ICON_SVG : USER_ICON_SVG;

    const contentDiv = document.createElement('div');
    contentDiv.classList.add('message-content');
    
    if (text !== null) {
        contentDiv.innerText = text;
    }
    
    msgDiv.appendChild(iconDiv);
    msgDiv.appendChild(contentDiv);
    
    chatHistory.appendChild(msgDiv);
    scrollToBottom();

    if (returnElement) return contentDiv;
}

function scrollToBottom() {
    chatHistory.scrollTop = chatHistory.scrollHeight;
}