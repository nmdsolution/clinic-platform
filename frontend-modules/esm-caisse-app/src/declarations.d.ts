declare module '*.scss' {
  const content: Record<string, string>;
  export default content;
}

interface RequireContext {
  keys(): string[];
  <T = unknown>(id: string): T;
  resolve(id: string): string;
  id: string;
}

interface Require {
  context(
    directory: string,
    useSubdirectories?: boolean,
    regExp?: RegExp,
    mode?: 'sync' | 'eager' | 'weak' | 'lazy' | 'lazy-once',
  ): RequireContext;
}

interface NodeRequire extends Require {}
