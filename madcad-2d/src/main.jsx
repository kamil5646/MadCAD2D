import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import './style.css'; // Global styles

const container = document.getElementById('react-overlay');
const root = createRoot(container);
root.render(<App />);
