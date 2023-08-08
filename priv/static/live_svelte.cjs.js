var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
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
module.exports = __toCommonJS(live_svelte_exports);

// js/live_svelte/utils.js
function normalizeComponents(components) {
  if (!Array.isArray(components.default) || !Array.isArray(components.filenames))
    return components;
  const normalized = {};
  for (const [index, module2] of components.default.entries()) {
    const Component = module2.default;
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
  node.parentNode?.removeChild(node);
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
          const base64 = getAttributeJson(ref, "data-slots")[slotName];
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
  return {
    ...getAttributeJson(ref, "data-props"),
    ...getLiveJsonProps(ref),
    live: ref,
    $$slots: getSlots(ref),
    $$scope: {}
  };
}
function findSlotCtx(component) {
  return component.$$.ctx.find((ctxElement) => ctxElement?.default);
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
//# sourceMappingURL=live_svelte.cjs.js.map
