export type Live = {
    pushEvent(event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number
    pushEventTo(phxTarget: any, event: string, payload?: object, onReply?: (reply: any, ref: number) => void): number

    handleEvent(event: string, callback: (payload: any) => void): Function
    removeHandleEvent(callbackRef: Function): void

    upload(name: string, files: any): void
    uploadTo(phxTarget: any, name: string, files: any): void
}

export declare const getHooks: (components: object) => object
export declare const getRender: (components: object) => (name: string, props: object, slots: object) => any
