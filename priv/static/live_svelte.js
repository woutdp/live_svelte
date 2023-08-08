var LiveSvelte = (() => {
  var __defProp = Object.defineProperty;
  var __defProps = Object.defineProperties;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropDescs = Object.getOwnPropertyDescriptors;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getOwnPropSymbols = Object.getOwnPropertySymbols;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __propIsEnum = Object.prototype.propertyIsEnumerable;
  var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
  var __spreadValues = (a, b) => {
    for (var prop in b || (b = {}))
      if (__hasOwnProp.call(b, prop))
        __defNormalProp(a, prop, b[prop]);
    if (__getOwnPropSymbols)
      for (var prop of __getOwnPropSymbols(b)) {
        if (__propIsEnum.call(b, prop))
          __defNormalProp(a, prop, b[prop]);
      }
    return a;
  };
  var __spreadProps = (a, b) => __defProps(a, __getOwnPropDescs(b));
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // js/live_svelte/index.js
  var live_svelte_exports = {};
  __export(live_svelte_exports, {
    getHooks: () => getHooks,
    getRender: () => getRender
  });

  // js/live_svelte/utils.js
  function normalizeComponents(components) {
    if (!Array.isArray(components.default) || !Array.isArray(components.filenames))
      return components;
    const normalized = {};
    for (const [index, module] of components.default.entries()) {
      const Component = module.default;
      const name = components.filenames[index].replace("../svelte/", "").replace(".svelte", "");
      normalized[name] = Component;
    }
    return normalized;
  }

  // js/live_svelte/render.js
  function getRender(components) {
    components = normalizeComponents(components);
    return function render(name, props, slots) {
      const Component = components[name];
      const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v]));
      return Component.render(props, { $$slots });
    };
  }

  // js/live_svelte/hooks.js
  function getAttributeJson(ref, attributeName) {
    const data = ref.el.getAttribute(attributeName);
    return data ? JSON.parse(data) : {};
  }
  function detach(node) {
    var _a;
    (_a = node.parentNode) == null ? void 0 : _a.removeChild(node);
  }
  function insert(target, node, anchor) {
    target.insertBefore(node, anchor || null);
  }
  function noop() {
  }
  function getSlots(ref) {
    const slots = {};
    for (const slotName in getAttributeJson(ref, "data-slots")) {
      const slot = () => {
        return {
          getElement() {
            const bese64 = getAttributeJson(ref, "data-slots")[slotName];
            const element = document.createElement("div");
            element.innerHTML = atob(base64).trim();
            return element;
          },
          update() {
            detach(this.savedElement);
            this.savedElement = this.getElement();
            insert(this.savedTarget, this.savedElement, this.savedAnchor);
          },
          c: noop,
          m(target, anchor) {
            this.savedTarget = target;
            this.savedAnchor = anchor;
            this.savedElement = this.getElement();
            insert(this.savedTarget, this.savedElement, this.savedAnchor);
          },
          d(detaching) {
            if (detaching)
              detach(this.savedElement);
          },
          l: noop
        };
      };
      slots[slotName] = [slot];
    }
    return slots;
  }
  function getLiveJsonProps(ref) {
    const json = getAttributeJson(ref, "data-live-json");
    if (!Array.isArray(json))
      return json;
    const liveJsonData = {};
    for (const liveJsonVariable of json) {
      const data = window[liveJsonVariable];
      if (data)
        liveJsonData[liveJsonVariable] = data;
    }
    return liveJsonData;
  }
  function getProps(ref) {
    return __spreadProps(__spreadValues(__spreadValues({}, getAttributeJson(ref, "data-props")), getLiveJsonProps(ref)), {
      live: ref,
      $$slots: getSlots(ref),
      $$scope: {}
    });
  }
  function findSlotCtx(component) {
    return component.$$.ctx.find((ctxElement) => ctxElement == null ? void 0 : ctxElement.default);
  }
  function getHooks(components) {
    components = normalizeComponents(components);
    const SvelteHook = {
      mounted() {
        const componentName = this.el.getAttribute("data-name");
        if (!componentName) {
          throw new Error("Component name must be provided");
        }
        const Component = components[componentName];
        if (!Component) {
          throw new Error(`Unable to find ${componentName} component.`);
        }
        for (const liveJsonElement of Object.keys(getAttributeJson(this, "data-live-json"))) {
          window.addEventListener(`${liveJsonElement}_initialized`, (event) => this._instance.$set(getProps(this)), false);
          window.addEventListener(`${liveJsonElement}_patched`, (event) => this._instance.$set(getProps(this)), false);
        }
        this._instance = new Component({
          target: this.el,
          props: getProps(this),
          hydrate: this.el.hasAttribute("data-ssr")
        });
      },
      updated() {
        this._instance.$set(getProps(this));
        const slotCtx = findSlotCtx(this._instance);
        for (const key in slotCtx) {
          slotCtx[key][0]().update();
        }
      },
      destroyed() {
      }
    };
    return {
      SvelteHook
    };
  }
  return __toCommonJS(live_svelte_exports);
})();
