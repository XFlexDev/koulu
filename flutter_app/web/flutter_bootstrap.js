{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerVersion = {{flutter_service_worker_version}};
_flutter.buildConfig.builds = _flutter.buildConfig.builds.map((build) => ({
  ...build,
  mainJsPath: `${build.mainJsPath}?v=${serviceWorkerVersion}`,
}));

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion,
  },
});
