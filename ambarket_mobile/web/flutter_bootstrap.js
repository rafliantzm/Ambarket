{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    
    // Remove the boot loader after flutter app is running
    const loader = document.getElementById('ambarket-boot-loader');
    if (loader) {
      loader.classList.add('boot-loader--exit');
      setTimeout(() => {
        loader.remove();
      }, 350);
    }
  }
});
