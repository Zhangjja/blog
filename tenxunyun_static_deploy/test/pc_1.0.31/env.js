(function (window) {

  var config = {
    WEPAPI: {
      SERVER_IP: "",
      PATH: "", //"/api",
    },
    WEBSOCKET: {
      PROTOCOL: "ws", // ws or wss
      SERVER_IP: "",
      PATH: "/capture",
    },
    STORAGE: {
      SERVER_IP: "",
      PATH: "/photos"
    },
    H5: {
      SERVER_IP: "",
      PORT: "10112",
    },
    BatchUploadServer: "",
    PLUGIN_VERSION: '' // 插件版本
  }

  window.__env = window.__env || {};
  window.__env.config = config
  window.__env.enableDebug = false;
}(this));
