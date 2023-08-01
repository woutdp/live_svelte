export type Live = {
    pushEvent(event: string, payload: object, onReply: (reply: any, ref: number) => void): number
    pushEventTo(phxTarget: any, event: string, payload: object, onReply: (reply: any, ref: number) => void): number

    handleEvent(event: string, callback: (payload: any) => void): Function
    removeHandleEvent(callbackRef: Function): void

    upload(name: string, files: any): void
    uploadTo(phxTarget: any, name: string, files: any): void
}

export declare const render: (name: string, props: object, slots: object) => any
export declare const getHooks: (components: {default: any[]; filenames: string[]}) => object
export declare const exportSvelteComponents: (components: {default: any[]; filenames: string[]}) => object
