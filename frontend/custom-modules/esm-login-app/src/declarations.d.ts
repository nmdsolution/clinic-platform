declare module '*.scss' {
  const content: Record<string, string>;
  export default content;
}

declare module '*.jpg' {
  const src: string;
  export default src;
}

declare module '*.png' {
  const src: string;
  export default src;
}

interface Window {
  applicationVersion?: string;
}
