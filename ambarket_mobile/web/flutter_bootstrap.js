{{flutter_js}}
{{flutter_build_config}}

(() => {
  const loaderId = 'ambarket-boot-loader';

  function removeBootLoader() {
    if (typeof window.removeSplashFromWeb === 'function') {
      window.removeSplashFromWeb();
    }

    const loader = document.getElementById(loaderId);
    if (loader) {
      loader.classList.add('boot-loader--exit');
      setTimeout(() => {
        loader.remove();
      }, 350);
    }
  }

  function showBootError() {
    const errorBtn = document.getElementById('boot-error-btn');
    const statusText = document.querySelector('.boot-status');
    if (errorBtn && statusText) {
      errorBtn.style.display = 'block';
      statusText.textContent = 'Ambarket belum dapat dimuat.';
    }
  }

  window.addEventListener('flutter-first-frame', removeBootLoader, {
    once: true,
  });

  window.addEventListener('ambarket-flutter-mounted', removeBootLoader, {
    once: true,
  });

  const loadResult = _flutter.loader.load();
  if (loadResult && typeof loadResult.catch === 'function') {
    loadResult.catch(() => {
      showBootError();
    });
  }
})();
