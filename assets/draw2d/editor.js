const READY_MESSAGE = 'Draw2D placeholder booted';

function emitReadySignal(message) {
  if (window.Draw2dReadyChannel &&
      typeof window.Draw2dReadyChannel.postMessage === 'function') {
    window.Draw2dReadyChannel.postMessage(message);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  console.log(READY_MESSAGE);
  emitReadySignal(READY_MESSAGE);
});

// Simulate Draw2D boot sequence placeholder
setTimeout(() => {
  const placeholder = document.getElementById('draw2d-placeholder');
  if (!placeholder) {
    return;
  }

  placeholder.querySelector('p').textContent =
    'Draw2D placeholder is ready.';
  placeholder.classList.add('ready');
}, 300);
