{{flutter_js}}
{{flutter_build_config}}

const loadingDiv = document.querySelector('#loading');

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    
    // Hide the loader with a smooth transition once the engine is initialized
    if (loadingDiv) {
      loadingDiv.style.transition = 'opacity 0.4s ease-out';
      loadingDiv.style.opacity = '0';
      setTimeout(() => {
        loadingDiv.remove();
      }, 400);
    }
    
    await appRunner.runApp();
  }
});
