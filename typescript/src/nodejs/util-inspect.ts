let util: any = undefined; try { util = await import('node:util'); } catch (e) { }
export const INSPECT_CUSTOM = util?.inspect?.custom ? util.inspect.custom : "util.inspect.custom";
export type InspectOptions =  typeof util extends undefined ? any : typeof util.InspectOptions;
export type Inspect = typeof util extends undefined ? any: typeof util.inspect;
