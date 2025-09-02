// Custom JavaScript for GroupVAN API Documentation

document.addEventListener('DOMContentLoaded', function() {
    // Add copy buttons to code blocks
    addCopyButtons();
    
    // Initialize code tabs
    initializeCodeTabs();
    
    // Add smooth scrolling
    addSmoothScrolling();
});

// Add copy buttons to all code blocks
function addCopyButtons() {
    const codeBlocks = document.querySelectorAll('pre.highlight');
    
    codeBlocks.forEach(block => {
        const button = document.createElement('button');
        button.className = 'code-copy-button';
        button.textContent = 'Copy';
        
        button.addEventListener('click', () => {
            const code = block.querySelector('code').textContent;
            navigator.clipboard.writeText(code).then(() => {
                button.textContent = 'Copied!';
                button.classList.add('copied');
                
                setTimeout(() => {
                    button.textContent = 'Copy';
                    button.classList.remove('copied');
                }, 2000);
            });
        });
        
        block.style.position = 'relative';
        block.appendChild(button);
    });
}

// Initialize tabbed code examples
function initializeCodeTabs() {
    const tabContainers = document.querySelectorAll('.code-tabs');
    
    tabContainers.forEach(container => {
        const buttons = container.querySelectorAll('.tab-buttons button');
        const panes = container.querySelectorAll('.tab-pane');
        
        buttons.forEach((button, index) => {
            button.addEventListener('click', () => {
                // Remove active class from all buttons and panes
                buttons.forEach(btn => btn.classList.remove('active'));
                panes.forEach(pane => pane.classList.remove('active'));
                
                // Add active class to clicked button and corresponding pane
                button.classList.add('active');
                panes[index].classList.add('active');
            });
        });
    });
}

// Add smooth scrolling to anchor links
function addSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Create tabbed code example
window.createCodeTabs = function(languages) {
    const container = document.createElement('div');
    container.className = 'code-tabs';
    
    const buttonContainer = document.createElement('div');
    buttonContainer.className = 'tab-buttons';
    
    const contentContainer = document.createElement('div');
    contentContainer.className = 'tab-content';
    
    languages.forEach((lang, index) => {
        // Create button
        const button = document.createElement('button');
        button.textContent = lang.name;
        if (index === 0) button.classList.add('active');
        buttonContainer.appendChild(button);
        
        // Create pane
        const pane = document.createElement('div');
        pane.className = 'tab-pane';
        if (index === 0) pane.classList.add('active');
        pane.innerHTML = lang.content;
        contentContainer.appendChild(pane);
    });
    
    container.appendChild(buttonContainer);
    container.appendChild(contentContainer);
    
    return container;
};