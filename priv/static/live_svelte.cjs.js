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
  exportSvelteComponents: () => exportSvelteComponents,
  getHooks: () => getHooks,
  render: () => render
});
module.exports = __toCommonJS(live_svelte_exports);

// js/live_svelte/render.js
function render(name, props = {}, slots = null) {
  if (require.resolve(__filename) in require.cache) {
    delete require.cache[require.resolve(__filename)];
  }
  const component = require(__filename)[name].default;
  const $$slots = Object.fromEntries(Object.entries(slots).map(([k, v]) => [k, () => v])) || {};
  return component.render(props, { $$slots, context: /* @__PURE__ */ new Map() });
}

// ../node_modules/svelte/internal/index.mjs
function noop() {
}
function run(fn) {
  return fn();
}
function run_all(fns) {
  fns.forEach(run);
}
function is_function(thing) {
  return typeof thing === "function";
}
function is_empty(obj) {
  return Object.keys(obj).length === 0;
}
function insert(target, node, anchor) {
  target.insertBefore(node, anchor || null);
}
function detach(node) {
  if (node.parentNode) {
    node.parentNode.removeChild(node);
  }
}
var render_callbacks = [];
function flush_render_callbacks(fns) {
  const filtered = [];
  const targets = [];
  render_callbacks.forEach((c) => fns.indexOf(c) === -1 ? filtered.push(c) : targets.push(c));
  targets.forEach((c) => c());
  render_callbacks = filtered;
}
var globals = typeof window !== "undefined" ? window : typeof globalThis !== "undefined" ? globalThis : global;
var _boolean_attributes = [
  "allowfullscreen",
  "allowpaymentrequest",
  "async",
  "autofocus",
  "autoplay",
  "checked",
  "controls",
  "default",
  "defer",
  "disabled",
  "formnovalidate",
  "hidden",
  "inert",
  "ismap",
  "itemscope",
  "loop",
  "multiple",
  "muted",
  "nomodule",
  "novalidate",
  "open",
  "playsinline",
  "readonly",
  "required",
  "reversed",
  "selected"
];
var boolean_attributes = /* @__PURE__ */ new Set([..._boolean_attributes]);
function destroy_component(component, detaching) {
  const $$ = component.$$;
  if ($$.fragment !== null) {
    flush_render_callbacks($$.after_update);
    run_all($$.on_destroy);
    $$.fragment && $$.fragment.d(detaching);
    $$.on_destroy = $$.fragment = null;
    $$.ctx = [];
  }
}
var SvelteElement;
if (typeof HTMLElement === "function") {
  SvelteElement = class extends HTMLElement {
    constructor() {
      super();
      this.attachShadow({ mode: "open" });
    }
    connectedCallback() {
      const { on_mount } = this.$$;
      this.$$.on_disconnect = on_mount.map(run).filter(is_function);
      for (const key in this.$$.slotted) {
        this.appendChild(this.$$.slotted[key]);
      }
    }
    attributeChangedCallback(attr, _oldValue, newValue) {
      this[attr] = newValue;
    }
    disconnectedCallback() {
      run_all(this.$$.on_disconnect);
    }
    $destroy() {
      destroy_component(this, 1);
      this.$destroy = noop;
    }
    $on(type, callback) {
      if (!is_function(callback)) {
        return noop;
      }
      const callbacks = this.$$.callbacks[type] || (this.$$.callbacks[type] = []);
      callbacks.push(callback);
      return () => {
        const index = callbacks.indexOf(callback);
        if (index !== -1)
          callbacks.splice(index, 1);
      };
    }
    $set($$props) {
      if (this.$$set && !is_empty($$props)) {
        this.$$.skip_bound = true;
        this.$$set($$props);
        this.$$.skip_bound = false;
      }
    }
  };
}

// js/live_svelte/utils.js
function exportSvelteComponents(components) {
  let { default: modules, filenames } = components;
  filenames = filenames.map((name) => name.replace("../svelte/", "")).map((name) => name.replace(".svelte", ""));
  return Object.assign({}, ...modules.map((m, index) => ({ [filenames[index]]: m.default })));
}

// js/live_svelte/hooks.js
function base64ToElement(base64) {
  let template = document.createElement("div");
  template.innerHTML = atob(base64).trim();
  return template;
}
function dataAttributeToJson(attributeName, el) {
  const data = el.getAttribute(attributeName);
  return data ? JSON.parse(data) : {};
}
function createSlots(slots, ref) {
  const createSlot = (slotName, ref2) => {
    let savedTarget, savedAnchor, savedElement;
    return () => {
      return {
        getElement() {
          return base64ToElement(dataAttributeToJson("data-slots", ref2.el)[slotName]);
        },
        update() {
          const element = this.getElement();
          detach(savedElement);
          insert(savedTarget, element, savedAnchor);
          savedElement = element;
        },
        c: noop,
        m(target, anchor) {
          const element = this.getElement();
          savedTarget = target;
          savedAnchor = anchor;
          savedElement = element;
          insert(target, element, anchor);
        },
        d(detaching) {
          if (detaching)
            detach(savedElement);
        },
        l: noop
      };
    };
  };
  const svelteSlots = {};
  for (const slotName in slots) {
    svelteSlots[slotName] = [createSlot(slotName, ref)];
  }
  return svelteSlots;
}
function getLiveJsonProps(ref) {
  json = dataAttributeToJson("data-live-json", ref.el);
  if (typeof json === "object" && json !== null && !Array.isArray(json))
    return json;
  liveJsonData = {};
  for (const liveJsonVariable of json) {
    let data = window[liveJsonVariable];
    if (data)
      liveJsonData[liveJsonVariable] = data;
  }
  return liveJsonData;
}
function getProps(ref) {
  return {
    ...dataAttributeToJson("data-props", ref.el),
    ...getLiveJsonProps(ref),
    pushEvent: (event, data, callback) => ref.pushEvent(event, data, callback),
    pushEventTo: (selectorOrTarget, event, data, callback) => ref.pushEventTo(selectorOrTarget, event, data, callback),
    $$slots: createSlots(dataAttributeToJson("data-slots", ref.el), ref),
    $$scope: {}
  };
}
function findSlotCtx(component) {
  return component.$$.ctx.find((ctxElement) => ctxElement?.default);
}
function getHooks(Components) {
  const components = exportSvelteComponents(Components);
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
      for (const liveJsonElement of Object.keys(dataAttributeToJson("data-live-json", this.el))) {
        window.addEventListener(`${liveJsonElement}_initialized`, (event) => this._instance.$set(getProps(this)), false);
        window.addEventListener(`${liveJsonElement}_patched`, (event) => this._instance.$set(getProps(this)), false);
      }
      this._instance = new Component({
        target: this.el,
        props: getProps(this),
        hydrate: true
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
