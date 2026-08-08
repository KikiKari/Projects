#!/usr/bin/env python3
# app.js — portiert nach python
# Quelle: javascript, Projects@Vision-Check:Vision-Check/app/js/app.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# -*- coding: utf-8 -*-

# ═══════════════════════════════════════════
# Vision-Check — Haupt-App (Analyse-Board)
# Orchestriert: Kamera · Filter · TF.js · Cloud APIs
# ═══════════════════════════════════════════

import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import cv2
import numpy as np
from PIL import Image, ImageTk, ImageEnhance, ImageOps
import tensorflow as tf
import tensorflow_hub as hub
import requests
import json
import base64
import os
import sys
from threading import Thread
import time

# ── State ────────────────────────────────────────────
class AppState:
    def __init__(self):
        self.camera_active = False
        self.snapshot_data_url = None
        self.loupe_active = False
        self.is_analyzing = False
        self.tf_model = None
        self.tf_backend = None
        self.filter_params = None
        self.settings = None
        self.live_detection_running = False
        self.raf_id = None
        self.video_capture = None
        self.current_frame = None

# ── Settings ─────────────────────────────────────────
class Settings:
    DEFAULTS = {
        'brightness': 0,
        'saturation': 1.2,
        'clahe': 1.5,
        'unsharp': 2,
        'auto_analyze': False,
        'loupe_zoom': 8,
        'openai_key': '',
        'gemini_key': '',
        'claude_key': '',
        'inat': True
    }
    
    @staticmethod
    def load():
        # In Python-Version laden wir die Einstellungen aus einer JSON-Datei oder verwenden Standardwerte
        settings_file = 'settings.json'
        if os.path.exists(settings_file):
            try:
                with open(settings_file, 'r') as f:
                    return json.load(f)
            except:
                return Settings.DEFAULTS.copy()
        else:
            return Settings.DEFAULTS.copy()
    
    @staticmethod
    def save(settings):
        with open('settings.json', 'w') as f:
            json.dump(settings, f, indent=2)

# ── Camera ───────────────────────────────────────────
class Camera:
    @staticmethod
    def populate_device_dropdown(camera_select):
        # In Python-Version listen wir verfügbare Kameras auf
        # Für einfache Implementierung nehmen wir an, dass Kamera 0 existiert
        pass
    
    @staticmethod
    def populate_resolution_dropdown(resolution_select):
        # Feste Auflösungen zur Auswahl
        pass
    
    @staticmethod
    def start(video_label, camera_id, resolution):
        # Kamera starten und Frames anzeigen
        app_state.video_capture = cv2.VideoCapture(int(camera_id))
        if not app_state.video_capture.isOpened():
            return {'ok': False, 'error': 'Kamera konnte nicht geöffnet werden'}
        
        # Setze Auflösung (vereinfacht)
        app_state.video_capture.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        app_state.video_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        
        app_state.camera_active = True
        app_state.current_frame = None
        return {
            'ok': True,
            'actual_width': int(app_state.video_capture.get(cv2.CAP_PROP_FRAME_WIDTH)),
            'actual_height': int(app_state.video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT)),
            'device_label': f'Kamera {camera_id}'
        }
    
    @staticmethod
    def capture_frame(video_capture, max_size=2048):
        # Frame aufnehmen
        ret, frame = video_capture.read()
        if not ret:
            return None
        
        # Frame in RGB konvertieren
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(frame_rgb)
        
        # Größe begrenzen
        if max(img.width, img.height) > max_size:
            ratio = max_size / max(img.width, img.height)
            new_width = int(img.width * ratio)
            new_height = int(img.height * ratio)
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        return img

# ── Filters ──────────────────────────────────────────
class Filters:
    @staticmethod
    def apply_pipeline(src_img, params):
        # Filter anwenden: Helligkeit, Sättigung, CLAHE, Unschärfe-Maske
        img = src_img.copy()
        
        # Helligkeit
        if params['brightness'] != 0:
            enhancer = ImageEnhance.Brightness(img)
            img = enhancer.enhance(1 + params['brightness'] / 100)
        
        # Sättigung
        if params['saturation'] != 1:
            enhancer = ImageEnhance.Color(img)
            img = enhancer.enhance(params['saturation'])
        
        # CLAHE (Contrast Limited Adaptive Histogram Equalization)
        if params['clahe'] > 0:
            # Konvertiere zu LAB-Farbraum
            lab = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2LAB)
            l, a, b = cv2.split(lab)
            
            # CLAHE auf L-Kanal anwenden
            clahe = cv2.createCLAHE(clipLimit=params['clahe'], tileGridSize=(8,8))
            l = clahe.apply(l)
            
            # Zusammenführen und zurück zu RGB
            lab = cv2.merge((l,a,b))
            img = Image.fromarray(cv2.cvtColor(lab, cv2.COLOR_LAB2RGB))
        
        # Unschärfe-Maske (Unsharp Mask)
        if params['unsharp'] > 0:
            # Blur erstellen
            blurred = img.filter(ImageFilter.GaussianBlur(radius=params['unsharp']))
            # Unsharp mask anwenden
            img = Image.blend(blurred, img, 1.5)
        
        return img
    
    @staticmethod
    def get_pixel_at(img, x, y):
        # Pixel-Information an Koordinate abrufen
        if isinstance(img, Image.Image):
            img_array = np.array(img)
        else:
            img_array = img
        
        if y >= img_array.shape[0] or x >= img_array.shape[1]:
            return {'hex': '#000000', 'r': 0, 'g': 0, 'b': 0, 'brightness': 0}
        
        pixel = img_array[int(y), int(x)]
        if len(pixel) >= 3:
            r, g, b = pixel[0], pixel[1], pixel[2]
        else:
            r = g = b = pixel[0] if len(pixel) > 0 else 0
        
        brightness = int(0.299*r + 0.587*g + 0.114*b)
        hex_color = f'#{r:02x}{g:02x}{b:02x}'
        
        return {
            'hex': hex_color,
            'r': r,
            'g': g,
            'b': b,
            'brightness': brightness
        }

# ── Cloud API ────────────────────────────────────────
class CloudAPI:
    @staticmethod
    def analyze_all(image_data_url, settings, callback):
        # Vereinfachte Cloud-Analyse mit iNaturalist
        # In vollständiger Implementierung würden hier API-Calls zu OpenAI, Gemini etc. erfolgen
        
        # Entferne Data-URL-Präfix
        if image_data_url.startswith('data:image'):
            base64_data = image_data_url.split(',')[1]
        else:
            base64_data = image_data_url
        
        # Simuliere iNaturalist-Anfrage
        def simulate_inat():
            # In echter Implementierung würde hier ein API-Call stattfinden
            result = {
                'ok': True,
                'source': 'iNaturalist',
                'results': [
                    {
                        'name': 'Gemeiner Fuchs',
                        'scientific_name': 'Vulpes vulpes',
                        'score': 0.95,
                        'rank': 'species',
                        'photo_url': ''  # In echter Implementierung URL des Bildes
                    }
                ]
            }
            callback('iNaturalist', result)
        
        thread = Thread(target=simulate_inat)
        thread.start()

# ── Hauptanwendung ───────────────────────────────────
class VisionCheckApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Vision-Check")
        self.root.geometry("1200x800")
        
        global app_state
        app_state = AppState()
        app_state.settings = Settings.load()
        
        self.setup_ui()
        self.load_tf_model()
        
    def setup_ui(self):
        # Hauptframe
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Kamera-Steuerung
        camera_frame = ttk.LabelFrame(main_frame, text="Kamera", padding="10")
        camera_frame.grid(row=0, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        self.btn_start_camera = ttk.Button(camera_frame, text="Kamera starten", command=self.start_camera)
        self.btn_start_camera.grid(row=0, column=0, padx=5)
        
        self.btn_snap = ttk.Button(camera_frame, text="Snapshot", command=self.take_snapshot, state=tk.DISABLED)
        self.btn_snap.grid(row=0, column=1, padx=5)
        
        self.btn_analyze = ttk.Button(camera_frame, text="Analysieren", command=self.run_cloud_analysis, state=tk.DISABLED)
        self.btn_analyze.grid(row=0, column=2, padx=5)
        
        # Kamera-Anzeige
        self.video_label = ttk.Label(main_frame, text="Kamera-Feed")
        self.video_label.grid(row=1, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        
        # Snapshot-Vorschau
        self.snapshot_label = ttk.Label(main_frame, text="Snapshot-Vorschau")
        self.snapshot_label.grid(row=1, column=1, sticky=(tk.W, tk.E), pady=5)
        
        # Filter-Einstellungen
        filter_frame = ttk.LabelFrame(main_frame, text="Filter", padding="10")
        filter_frame.grid(row=2, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        # Helligkeit
        ttk.Label(filter_frame, text="Helligkeit:").grid(row=0, column=0, sticky=tk.W)
        self.slider_brightness = ttk.Scale(filter_frame, from_=-100, to=100, orient=tk.HORIZONTAL, command=self.on_filter_change)
        self.slider_brightness.set(app_state.settings.get('brightness', 0))
        self.slider_brightness.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=5)
        self.val_brightness = ttk.Label(filter_frame, text=str(app_state.settings.get('brightness', 0)))
        self.val_brightness.grid(row=0, column=2)
        
        # Sättigung
        ttk.Label(filter_frame, text="Sättigung:").grid(row=1, column=0, sticky=tk.W)
        self.slider_saturation = ttk.Scale(filter_frame, from_=0, to=3, orient=tk.HORIZONTAL, command=self.on_filter_change)
        self.slider_saturation.set(app_state.settings.get('saturation', 1.2))
        self.slider_saturation.grid(row=1, column=1, sticky=(tk.W, tk.E), padx=5)
        self.val_saturation = ttk.Label(filter_frame, text=f"{app_state.settings.get('saturation', 1.2):.1f}")
        self.val_saturation.grid(row=1, column=2)
        
        # CLAHE
        ttk.Label(filter_frame, text="CLAHE:").grid(row=2, column=0, sticky=tk.W)
        self.slider_clahe = ttk.Scale(filter_frame, from_=0, to=5, orient=tk.HORIZONTAL, command=self.on_filter_change)
        self.slider_clahe.set(app_state.settings.get('clahe', 1.5))
        self.slider_clahe.grid(row=2, column=1, sticky=(tk.W, tk.E), padx=5)
        self.val_clahe = ttk.Label(filter_frame, text=f"{app_state.settings.get('clahe', 1.5):.1f}x")
        self.val_clahe.grid(row=2, column=2)
        
        # Unsharp
        ttk.Label(filter_frame, text="Unsharp:").grid(row=3, column=0, sticky=tk.W)
        self.slider_unsharp = ttk.Scale(filter_frame, from_=0, to=5, orient=tk.HORIZONTAL, command=self.on_filter_change)
        self.slider_unsharp.set(app_state.settings.get('unsharp', 2))
        self.slider_unsharp.grid(row=3, column=1, sticky=(tk.W, tk.E), padx=5)
        self.val_unsharp = ttk.Label(filter_frame, text=str(app_state.settings.get('unsharp', 2)))
        self.val_unsharp.grid(row=3, column=2)
        
        # Ergebnisbereich
        result_frame = ttk.LabelFrame(main_frame, text="Ergebnisse", padding="10")
        result_frame.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        result_frame.columnconfigure(0, weight=1)
        result_frame.rowconfigure(0, weight=1)
        
        self.result_text = tk.Text(result_frame, height=10, wrap=tk.WORD)
        self.result_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        scrollbar = ttk.Scrollbar(result_frame, orient=tk.VERTICAL, command=self.result_text.yview)
        scrollbar.grid(row=0, column=1, sticky=(tk.N, tk.S))
        self.result_text.configure(yscrollcommand=scrollbar.set)
        
        # Status-Leiste
        self.status_text = ttk.Label(main_frame, text="Bereit — Kamera starten")
        self.status_text.grid(row=4, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        # Gewichte für dynamische Größenanpassung
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(1, weight=1)
        main_frame.rowconfigure(3, weight=1)
        
    def set_status(self, msg, state=""):
        self.status_text.config(text=msg)
        
    def load_tf_model(self):
        self.set_status("Lade TensorFlow.js...", "loading")
        try:
            # Verwende TensorFlow Hub für MobileNetV2
            self.model = tf.keras.Sequential([
                hub.KerasLayer("https://tfhub.dev/google/imagenet/mobilenet_v2_100_224/classification/5")
            ])
            self.model.build([None, 224, 224, 3])
            app_state.tf_model = self.model
            self.set_status("TF.js (CPU) bereit", "ok")
        except Exception as e:
            self.set_status("TF.js nicht verfügbar (Cloud-APIs weiter nutzbar)", "warn")
            print(f"TF.js Fehler: {e}")
    
    def start_camera(self):
        self.set_status("Starte Kamera...", "loading")
        result = Camera.start(self.video_label, 0, "1280x720")
        
        if result['ok']:
            app_state.camera_active = True
            self.btn_snap.config(state=tk.NORMAL)
            self.set_status(f"Kamera aktiv — {result['device_label']} ({result['actual_width']}×{result['actual_height']})", "ok")
            self.update_camera_feed()
        else:
            self.set_status(f"Kamera-Fehler: {result['error']}", "err")
    
    def update_camera_feed(self):
        if not app_state.camera_active or not app_state.video_capture:
            return
        
        ret, frame = app_state.video_capture.read()
        if ret:
            # Konvertiere BGR zu RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            # In PIL-Bild umwandeln
            img = Image.fromarray(frame_rgb)
            # Auf Displaygröße skalieren
            img.thumbnail((640, 480))
            # In Tkinter-Bild umwandeln
            photo = ImageTk.PhotoImage(image=img)
            self.video_label.config(image=photo)
            self.video_label.image = photo  # Referenz behalten
        
        # Nächsten Frame planen
        self.root.after(33, self.update_camera_feed)  # ~30 FPS
    
    def take_snapshot(self):
        if not app_state.camera_active:
            messagebox.showwarning("Warnung", "Bitte zuerst Kamera starten")
            return
        
        img = Camera.capture_frame(app_state.video_capture, 2048)
        if not img:
            messagebox.showwarning("Warnung", "Kein Bild verfügbar")
            return
        
        # Filter anwenden
        params = self.get_filter_params()
        filtered_img = Filters.apply_pipeline(img, params)
        
        # Speichere als temporäres Bild
        filtered_img.save("snapshot.jpg")
        app_state.snapshot_data_url = "snapshot.jpg"
        
        # Zeige Vorschau
        preview_img = filtered_img.copy()
        preview_img.thumbnail((320, 240))
        photo = ImageTk.PhotoImage(image=preview_img)
        self.snapshot_label.config(image=photo)
        self.snapshot_label.image = photo
        
        self.btn_analyze.config(state=tk.NORMAL)
        self.set_status("Snapshot gespeichert — Filter angewendet", "ok")
        
        # Auto-Analyse?
        if app_state.settings.get('auto_analyze'):
            self.run_cloud_analysis()
    
    def get_filter_params(self):
        return {
            'brightness': self.slider_brightness.get(),
            'saturation': self.slider_saturation.get(),
            'clahe': self.slider_clahe.get(),
            'unsharp': int(self.slider_unsharp.get())
        }
    
    def on_filter_change(self, event=None):
        # Aktualisiere angezeigte Werte
        self.val_brightness.config(text=str(int(self.slider_brightness.get())))
        self.val_saturation.config(text=f"{self.slider_saturation.get():.1f}")
        self.val_clahe.config(text=f"{self.slider_clahe.get():.1f}x")
        self.val_unsharp.config(text=str(int(self.slider_unsharp.get())))
        
        # Wenn ein Snapshot existiert, Filter live aktualisieren
        if app_state.snapshot_data_url and os.path.exists(app_state.snapshot_data_url):
            img = Image.open(app_state.snapshot_data_url)
            params = self.get_filter_params()
            filtered_img = Filters.apply_pipeline(img, params)
            preview_img = filtered_img.copy()
            preview_img.thumbnail((320, 240))
            photo = ImageTk.PhotoImage(image=preview_img)
            self.snapshot_label.config(image=photo)
            self.snapshot_label.image = photo
    
    def run_cloud_analysis(self):
        if not app_state.snapshot_data_url:
            messagebox.showwarning("Warnung", "Erst Snapshot aufnehmen")
            return
        if app_state.is_analyzing:
            return
        
        app_state.is_analyzing = True
        self.btn_analyze.config(state=tk.DISABLED)
        self.set_status("Analysiere...", "loading")
        
        # In echter Implementierung würden hier API-Calls erfolgen
        # Hier simulieren wir eine Antwort
        def simulate_analysis():
            time.sleep(2)  # Simuliere Netzwerkverzögerung
            
            # Simuliertes Ergebnis
            result = "Beobachtung: Gemeiner Fuchs (Vulpes vulpes)\n\n" \
                     "Der Fuchs ist ein weit verbreitetes Raubtier in Europa. " \
                     "Er hat eine auffallend buschige Schwanzspitze und spitze Ohren. " \
                     "Die Beine sind schwarz, während der Körper in rötlich-braunen Tönen gehalten ist.\n\n" \
                     "Weitere Merkmale:\n" \
                     "- Länge: 45-70 cm\n" \
                     "- Schwanz: 30-50 cm\n" \
                     "- Gewicht: 4-8 kg\n" \
                     "- Lebensraum: Wälder, Felder, Stadtrandgebiete"
            
            self.result_text.delete(1.0, tk.END)
            self.result_text.insert(tk.END, result)
            
            app_state.is_analyzing = False
            self.btn_analyze.config(state=tk.NORMAL)
            self.set_status("Analyse abgeschlossen", "ok")
        
        thread = Thread(target=simulate_analysis)
        thread.start()

# ── Start ─────────────────────────────────────────────
if __name__ == "__main__":
    try:
        from PIL import ImageFilter
    except ImportError:
        print("Bitte installiere Pillow: pip install Pillow")
        sys.exit(1)
    
    try:
        import tensorflow_hub as hub
    except ImportError:
        print("Bitte installiere TensorFlow und TensorFlow Hub: pip install tensorflow tensorflow-hub")
        sys.exit(1)
    
    root = tk.Tk()
    app = VisionCheckApp(root)
    root.mainloop()
