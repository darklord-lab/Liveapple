import { useEffect, useRef } from 'react';
import { App as CapApp } from '@capacitor/app';

interface MobileNavigationOptions {
  onBack: () => void;
  enabled?: boolean;
}

export function useMobileNavigation({ onBack, enabled = true }: MobileNavigationOptions) {
  const onBackRef = useRef(onBack);
  onBackRef.current = onBack;

  // 1. Capacitor Native Android Back Button & Edge Gesture Navigation
  useEffect(() => {
    if (!enabled) return;
    let listener: any = null;

    try {
      CapApp.addListener('backButton', () => {
        onBackRef.current();
      })
        .then((l) => {
          listener = l;
        })
        .catch(() => {});
    } catch {
      // not in capacitor environment
    }

    return () => {
      if (listener && typeof listener.remove === 'function') {
        listener.remove();
      }
    };
  }, [enabled]);

  // 2. Browser History / Popstate Support (Android WebView system back)
  useEffect(() => {
    if (!enabled) return;

    window.history.pushState({ modalOpen: true, timestamp: Date.now() }, '');

    const handlePopState = () => {
      onBackRef.current();
    };

    window.addEventListener('popstate', handlePopState);
    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  }, [enabled]);

  // 3. Motion Navigation Touch Gestures (Left slide, right swipe, edge swipe)
  const touchStartRef = useRef<{ x: number; y: number; time: number } | null>(null);

  const onTouchStart = (e: React.TouchEvent) => {
    if (e.touches.length === 1) {
      touchStartRef.current = {
        x: e.touches[0].clientX,
        y: e.touches[0].clientY,
        time: Date.now(),
      };
    }
  };

  const onTouchEnd = (e: React.TouchEvent) => {
    if (!touchStartRef.current || e.changedTouches.length === 0) return;
    const deltaX = e.changedTouches[0].clientX - touchStartRef.current.x;
    const deltaY = e.changedTouches[0].clientY - touchStartRef.current.y;
    const duration = Date.now() - touchStartRef.current.time;

    // Detect horizontal motion gesture:
    // Left slide (deltaX < -50px) or Right swipe (deltaX > 50px)
    // with horizontal motion dominance (abs(deltaX) > abs(deltaY) * 1.15) and quick gesture (< 650ms)
    const isHorizontal = Math.abs(deltaX) > Math.abs(deltaY) * 1.15;
    const isSwipeDistance = Math.abs(deltaX) > 50;
    const isQuick = duration < 650;

    if (isHorizontal && isSwipeDistance && isQuick) {
      onBackRef.current();
    }

    touchStartRef.current = null;
  };

  return {
    touchHandlers: {
      onTouchStart,
      onTouchEnd,
    },
  };
}
