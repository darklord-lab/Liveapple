// Client-side PDF page rendering helper using PDF.js

let pdfjsPromise: Promise<any> | null = null;

export function loadPdfJs(): Promise<any> {
  if (pdfjsPromise) return pdfjsPromise;

  pdfjsPromise = new Promise((resolve, reject) => {
    if (typeof window !== 'undefined' && (window as any).pdfjsLib) {
      resolve((window as any).pdfjsLib);
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js';
    script.async = true;

    script.onload = () => {
      const lib = (window as any).pdfjsLib;
      if (lib) {
        lib.GlobalWorkerOptions.workerSrc =
          'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
        resolve(lib);
      } else {
        reject(new Error('PDF.js failed to initialize.'));
      }
    };

    script.onerror = () => {
      reject(new Error('Failed to load PDF.js script from CDN.'));
    };

    document.head.appendChild(script);
  });

  return pdfjsPromise;
}

export async function renderPdfPages(file: File): Promise<string[]> {
  const lib = await loadPdfJs();
  const arrayBuffer = await file.arrayBuffer();
  const loadingTask = lib.getDocument({ data: arrayBuffer });
  const pdf = await loadingTask.promise;
  const numPages = pdf.numPages;
  const renderedPages: string[] = [];

  // Render up to first 10 pages into high-res images
  const maxPages = Math.min(numPages, 10);
  for (let i = 1; i <= maxPages; i++) {
    const page = await pdf.getPage(i);
    const viewport = page.getViewport({ scale: 1.5 });
    const canvas = document.createElement('canvas');
    canvas.width = viewport.width;
    canvas.height = viewport.height;
    const ctx = canvas.getContext('2d');

    if (ctx) {
      await page.render({ canvasContext: ctx, viewport }).promise;
      renderedPages.push(canvas.toDataURL('image/png'));
    }
  }

  return renderedPages;
}
