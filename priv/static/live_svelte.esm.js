var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __require = /* @__PURE__ */ ((x) => typeof require !== "undefined" ? require : typeof Proxy !== "undefined" ? new Proxy(x, {
  get: (a, b) => (typeof require !== "undefined" ? require : a)[b]
}) : x)(function(x) {
  if (typeof require !== "undefined")
    return require.apply(this, arguments);
  throw new Error('Dynamic require of "' + x + '" is not supported');
});
var __commonJS = (cb, mod) => function __require2() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// js/live_svelte/render.js
var require_render = __commonJS({
  "js/live_svelte/render.js"(exports, module) {
    function getRender2(componentPath) {
      function render(name, props = {}, slots = null) {
        if (__require.resolve(componentPath) in __require.cache) {
          delete __require.cache[__require.resolve(componentPath)];
        }
        const component = __require(componentPath)[name].default;
        const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v])) || {};
        return component.render(props, { $$slots, context: /* @__PURE__ */ new Map() });
      }
      return render;
    }
    module.exports = {
      getRender: getRender2
    };
  }
});

// js/live_svelte/utils.js
var require_utils = __commonJS({
  "js/live_svelte/utils.js"(exports, module) {
    function exportSvelteComponents2(components) {
      let { default: modules, filenames } = components;
      filenames = filenames.map((name) => name.replace("../svelte/components/", "")).map((name) => name.replace(".svelte", ""));
      return Object.assign({}, ...modules.map((m, index) => ({ [filenames[index]]: m.default })));
    }
    module.exports = {
      exportSvelteComponents: exportSvelteComponents2
    };
  }
});

// js/live_svelte/index.js
var import_render = __toESM(require_render());
var import_render2 = __toESM(require_render());
var import_utils = __toESM(require_utils());
var export_exportSvelteComponents = import_utils.default;
var export_getHooks = import_render2.default;
var export_getRender = import_render.default;
export {
  export_exportSvelteComponents as exportSvelteComponents,
  export_getHooks as getHooks,
  export_getRender as getRender
};
//# sourceMappingURL=live_svelte.esm.js.map
