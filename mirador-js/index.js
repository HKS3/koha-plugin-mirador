// These are needed for Mirador to load React correctly
// when loaded as a module in the browser. Or something like that.
import React from 'react';
import ReactDOM from 'react-dom';
window.React = React;
window.ReactDOM = ReactDOM;

import Mirador from 'mirador';
import { miradorImageToolsPlugin } from 'mirador-image-tools';
import GalleryShortcut from './GalleryShortcut.jsx';

export default function installMirador(id, manifestId, language) {
    Mirador.viewer({
        id,
        language,
        windows: [{
            manifestId,
            imageToolsEnabled: true,
            // imageToolsOpen: false,
        }],
        window: {
            allowClose: false,
            allowFullscreen: true,
            defaultView: 'gallery',
        },
        workspaceControlPanel: {
            // per docs: Useful if you want to lock the viewer down to only the configured manifests.
            // the only valuable thing we lose is the fullscreen button, so we enable it elsewhere
            enabled: false,
        },
    }, [
        GalleryShortcut,
        ...miradorImageToolsPlugin,
    ]);
}
