#!/usr/bin/env python3
# CameraMultiZoom-CMcSPWP0.js — portiert nach python
# Quelle: javascript, Projects@Weather-Check:Weather-Check/assets/CameraMultiZoom-CMcSPWP0.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

import tkinter as tk
from tkinter import ttk, messagebox
import cv2
from PIL import Image, ImageTk
import threading
import time

class CameraMultiZoom:
    def __init__(self, root, on_capture=None, on_close=None, single_mode=False, label=None, require_ground=False):
        self.root = root
        self.on_capture = on_capture
        self.on_close = on_close
        self.single_mode = single_mode
        self.label = label
        self.require_ground = require_ground
        
        # Camera settings
        self.zoom_levels = [
            {"zoom": 0.6, "label": "Weitwinkel (0.6×)", "hint": "Himmel + Horizont breit"},
            {"zoom": 1, "label": "Normal (1×)", "hint": "Standardansicht"},
            {"zoom": 2, "label": "Tele (2×)", "hint": "Wolken/Horizont nah"}
        ]
        
        if self.single_mode:
            self.zoom_levels = [{"zoom": 1, "label": self.label or "Aufnahme", 
                               "hint": "Boden + Umgebung, Kamera nach unten/vorne" if self.require_ground else "Aufnahme erstellen"}]
        
        self.current_zoom_index = 0
        self.torch_on = False
        self.facing_mode = "environment"  # "environment" or "user"
        self.captures = []
        self.capture_urls = []
        
        # Camera variables
        self.cap = None
        self.video_thread = None
        self.stop_event = threading.Event()
        
        self.setup_ui()
        self.start_camera()

    def setup_ui(self):
        self.root.title("Kamera")
        self.root.geometry("400x700")
        self.root.configure(bg="black")
        
        # Header frame
        header_frame = tk.Frame(self.root, bg="black")
        header_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Close button
        close_btn = tk.Button(header_frame, text="×", command=self.close_app, 
                             bg="black", fg="white", font=("Arial", 16))
        close_btn.pack(side=tk.LEFT)
        
        # Title
        self.title_label = tk.Label(header_frame, text=self.zoom_levels[self.current_zoom_index]["label"],
                                   fg="white", bg="black", font=("Arial", 12, "bold"))
        self.title_label.pack(side=tk.LEFT, expand=True)
        
        if not self.single_mode:
            counter_label = tk.Label(header_frame, text=f"{self.current_zoom_index + 1} / {len(self.zoom_levels)}",
                                    fg="white", bg="black", font=("Arial", 10))
            counter_label.pack(side=tk.LEFT)
        
        # Torch and switch camera buttons
        button_frame = tk.Frame(header_frame, bg="black")
        button_frame.pack(side=tk.RIGHT)
        
        self.torch_btn = tk.Button(button_frame, text="💡", command=self.toggle_torch,
                                  bg="black", fg="white", font=("Arial", 14))
        self.torch_btn.pack(side=tk.LEFT, padx=5)
        
        switch_btn = tk.Button(button_frame, text="🔄", command=self.switch_camera,
                              bg="black", fg="white", font=("Arial", 14))
        switch_btn.pack(side=tk.LEFT)
        
        # Hint label
        self.hint_label = tk.Label(self.root, text=self.get_hint_text(),
                                  fg="white", bg="black", font=("Arial", 10))
        self.hint_label.pack(fill=tk.X, padx=20, pady=5)
        
        # Preview frame
        self.preview_frame = tk.Frame(self.root, bg="black")
        self.preview_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.video_label = tk.Label(self.preview_frame, bg="black")
        self.video_label.pack(fill=tk.BOTH, expand=True)
        
        # Capture button
        capture_frame = tk.Frame(self.root, bg="black")
        capture_frame.pack(fill=tk.X, padx=20, pady=20)
        
        capture_btn = tk.Button(capture_frame, text="●", command=self.capture_image,
                               bg="white", fg="black", font=("Arial", 20), width=4, height=2)
        capture_btn.pack(pady=10)
        
        capture_text = "Aufnehmen" if self.single_mode else f"{self.zoom_levels[self.current_zoom_index]['label']} aufnehmen"
        capture_label = tk.Label(capture_frame, text=capture_text, fg="white", bg="black")
        capture_label.pack()
        
        # Progress dots for multi-zoom mode
        if not self.single_mode:
            dots_frame = tk.Frame(self.root, bg="black")
            dots_frame.pack()
            
            for i in range(len(self.zoom_levels)):
                color = "white" if i == self.current_zoom_index else "gray"
                dot = tk.Label(dots_frame, text="●", fg=color, bg="black", font=("Arial", 16))
                dot.pack(side=tk.LEFT, padx=2)

    def get_hint_text(self):
        if self.require_ground and self.current_zoom_index == 0:
            return "📷 Kamera nach unten/vorne — Boden + Umgebung"
        return self.zoom_levels[self.current_zoom_index]["hint"]

    def start_camera(self):
        self.video_thread = threading.Thread(target=self.video_loop, daemon=True)
        self.video_thread.start()

    def video_loop(self):
        # Open camera
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            messagebox.showerror("Fehler", "Kamera konnte nicht geöffnet werden")
            return
            
        while not self.stop_event.is_set():
            ret, frame = self.cap.read()
            if ret:
                # Apply zoom if needed
                if not self.single_mode and len(self.zoom_levels) > self.current_zoom_index:
                    zoom = self.zoom_levels[self.current_zoom_index]["zoom"]
                    if zoom != 1:
                        h, w = frame.shape[:2]
                        center_x, center_y = w // 2, h // 2
                        new_w, new_h = int(w / zoom), int(h / zoom)
                        x1, y1 = center_x - new_w // 2, center_y - new_h // 2
                        x2, y2 = x1 + new_w, y1 + new_h
                        frame = frame[y1:y2, x1:x2]
                        # Resize back to original size for display
                        frame = cv2.resize(frame, (w, h))
                
                # Convert to PhotoImage
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = Image.fromarray(rgb_frame)
                imgtk = ImageTk.PhotoImage(image=img)
                
                # Update UI in main thread
                self.root.after(0, lambda: self.update_video_frame(imgtk))
            
            time.sleep(0.03)  # ~30 FPS

    def update_video_frame(self, imgtk):
        try:
            self.video_label.imgtk = imgtk
            self.video_label.configure(image=imgtk)
        except:
            pass

    def toggle_torch(self):
        # In a real implementation, you would control the camera's torch/flash
        self.torch_on = not self.torch_on
        self.torch_btn.config(bg="yellow" if self.torch_on else "black")

    def switch_camera(self):
        # In a real implementation, you would switch between front/back cameras
        self.facing_mode = "user" if self.facing_mode == "environment" else "environment"
        # Restart camera with new facing mode
        self.restart_camera()

    def restart_camera(self):
        if self.cap:
            self.cap.release()
        self.start_camera()

    def capture_image(self):
        # In a real implementation, you would capture the current frame
        # For this example, we'll just simulate a capture
        self.captures.append(f"capture_{len(self.captures)}.jpg")
        
        if self.single_mode or self.current_zoom_index >= len(self.zoom_levels) - 1:
            if self.on_capture:
                self.on_capture({
                    "files": self.captures,
                    "labels": [level["label"] for level in self.zoom_levels]
                })
        else:
            self.current_zoom_index += 1
            self.update_ui()

    def update_ui(self):
        self.title_label.config(text=self.zoom_levels[self.current_zoom_index]["label"])
        self.hint_label.config(text=self.get_hint_text())
        
        capture_text = "Aufnehmen" if self.single_mode else f"{self.zoom_levels[self.current_zoom_index]['label']} aufnehmen"
        for widget in self.root.winfo_children():
            if isinstance(widget, tk.Frame):
                for child in widget.winfo_children():
                    if isinstance(child, tk.Label) and child.cget("text").endswith("aufnehmen"):
                        child.config(text=capture_text)

    def close_app(self):
        self.stop_event.set()
        if self.cap:
            self.cap.release()
        if self.on_close:
            self.on_close()
        self.root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = CameraMultiZoom(root)
    root.mainloop()
