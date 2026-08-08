#!/usr/bin/env python3
# CameraCapture-Mm1yclT8.js — portiert nach python
# Quelle: javascript, Projects@Weather-Check:Weather-Check/assets/CameraCapture-Mm1yclT8.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

import tkinter as tk
from tkinter import ttk, filedialog
import cv2
from PIL import Image, ImageTk
import threading
import time
import os

class CameraCapture:
    def __init__(self, on_capture, on_close, direction_label=None):
        self.on_capture = on_capture
        self.on_close = on_close
        self.direction_label = direction_label or "Himmel + Horizont fotografieren"
        
        # Initialize state variables
        self.cap = None
        self.current_camera = "back"  # "front" or "back"
        self.state = "preview"  # "preview", "captured", "error"
        self.captured_image = None
        self.error_message = ""
        
        # Create main window
        self.root = tk.Tk()
        self.root.title("Kamera")
        self.root.geometry("800x600")
        self.root.configure(bg="black")
        
        # Make it fullscreen
        self.root.attributes('-fullscreen', True)
        
        # Create UI elements
        self.create_widgets()
        
        # Start camera
        self.start_camera()

    def create_widgets(self):
        # Close button
        self.close_btn = tk.Button(
            self.root,
            text="X",
            command=self.close,
            bg="black",
            fg="white",
            font=("Arial", 16),
            width=3,
            height=1
        )
        self.close_btn.place(x=750, y=10)

        # Direction label
        self.direction_lbl = tk.Label(
            self.root,
            text=f"Richtung: {self.direction_label}" if self.direction_label else "Himmel + Horizont fotografieren",
            bg="black",
            fg="white",
            font=("Arial", 12)
        )
        self.direction_lbl.place(x=200, y=60)

        # Video frame
        self.video_frame = tk.Frame(self.root, bg="black", width=800, height=400)
        self.video_frame.place(x=0, y=100)
        
        # Canvas for video display
        self.video_canvas = tk.Canvas(self.video_frame, width=760, height=360, bg="black")
        self.video_canvas.pack(pady=20)
        
        # Error frame
        self.error_frame = tk.Frame(self.root, bg="black")
        
        # Capture button frame
        self.button_frame = tk.Frame(self.root, bg="black")
        self.button_frame.place(x=0, y=500, width=800, height=100)
        
        # Initial button setup
        self.update_buttons()

    def start_camera(self):
        """Initialize and start the camera"""
        try:
            # For back camera use index 0, for front use 1 (may vary by device)
            camera_index = 0 if self.current_camera == "back" else 1
            self.cap = cv2.VideoCapture(camera_index)
            
            if not self.cap.isOpened():
                self.handle_camera_error("Keine Kamera gefunden.")
                return
                
            # Set resolution
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
            
            # Start video loop
            self.video_loop()
            
        except Exception as e:
            self.handle_camera_error(f"Kamera-Fehler: {str(e)}")

    def handle_camera_error(self, message):
        """Handle camera errors"""
        self.state = "error"
        self.error_message = message
        self.show_error_message()

    def show_error_message(self):
        """Display error message in the UI"""
        # Clear previous widgets
        for widget in self.video_frame.winfo_children():
            widget.destroy()
            
        # Create error display
        error_label = tk.Label(
            self.video_frame,
            text=self.error_message,
            bg="black",
            fg="white",
            font=("Arial", 14),
            wraplength=700
        )
        error_label.pack(expand=True)
        
        # Close button
        close_button = tk.Button(
            self.video_frame,
            text="Schließen",
            command=self.close,
            bg="gray",
            fg="white"
        )
        close_button.pack(pady=10)

    def video_loop(self):
        """Main video display loop"""
        if self.state != "preview":
            return
            
        ret, frame = self.cap.read()
        if ret:
            # Convert to RGB and resize
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame_resized = cv2.resize(frame_rgb, (760, 360))
            
            # Convert to ImageTk
            self.current_image = ImageTk.PhotoImage(image=Image.fromarray(frame_resized))
            
            # Update canvas
            self.video_canvas.create_image(0, 0, anchor=tk.NW, image=self.current_image)
        
        # Continue loop
        if self.state == "preview":
            self.root.after(30, self.video_loop)

    def switch_camera(self):
        """Switch between front and back camera"""
        self.current_camera = "front" if self.current_camera == "back" else "back"
        
        # Release current camera
        if self.cap:
            self.cap.release()
            
        # Start new camera
        self.start_camera()

    def capture_photo(self):
        """Capture current frame as photo"""
        if self.cap and self.cap.isOpened():
            ret, frame = self.cap.read()
            if ret:
                # Save captured image
                self.captured_image = frame
                self.state = "captured"
                
                # Show captured image
                self.show_captured_image()
                self.update_buttons()

    def show_captured_image(self):
        """Display the captured image"""
        if self.captured_image is not None:
            # Convert to RGB
            frame_rgb = cv2.cvtColor(self.captured_image, cv2.COLOR_BGR2RGB)
            frame_resized = cv2.resize(frame_rgb, (760, 360))
            
            # Convert to ImageTk
            self.captured_photo = ImageTk.PhotoImage(image=Image.fromarray(frame_resized))
            
            # Clear canvas and show image
            self.video_canvas.delete("all")
            self.video_canvas.create_image(0, 0, anchor=tk.NW, image=self.captured_photo)

    def retake_photo(self):
        """Retake photo - go back to preview mode"""
        self.state = "preview"
        self.captured_image = None
        self.update_buttons()
        
        # Clear canvas
        self.video_canvas.delete("all")
        
        # Restart video loop
        self.video_loop()

    def confirm_photo(self):
        """Confirm and save the captured photo"""
        if self.captured_image is not None:
            # Generate filename
            filename = f"weather-foto-{int(time.time())}.jpg"
            
            # Save image
            cv2.imwrite(filename, self.captured_image)
            
            # Call on_capture callback
            self.on_capture(filename)

    def update_buttons(self):
        """Update buttons based on current state"""
        # Clear previous buttons
        for widget in self.button_frame.winfo_children():
            widget.destroy()
            
        if self.state == "preview":
            # Camera switch button
            switch_btn = tk.Button(
                self.button_frame,
                text="Switch Camera",
                command=self.switch_camera,
                bg="black",
                fg="white"
            )
            switch_btn.pack(side=tk.LEFT, padx=20)
            
            # Capture button
            capture_btn = tk.Button(
                self.button_frame,
                text="Aufnehmen",
                command=self.capture_photo,
                bg="white",
                fg="black",
                font=("Arial", 12),
                width=15,
                height=2
            )
            capture_btn.pack(side=tk.RIGHT, padx=20)
            
        elif self.state == "captured":
            # Retake button
            retake_btn = tk.Button(
                self.button_frame,
                text="Nochmal",
                command=self.retake_photo,
                bg="gray",
                fg="white"
            )
            retake_btn.pack(side=tk.LEFT, padx=20)
            
            # Confirm button
            confirm_btn = tk.Button(
                self.button_frame,
                text="Bestätigen",
                command=self.confirm_photo,
                bg="green",
                fg="white",
                font=("Arial", 12),
                width=15,
                height=2
            )
            confirm_btn.pack(side=tk.RIGHT, padx=20)

    def close(self):
        """Close the camera and window"""
        # Release camera
        if self.cap:
            self.cap.release()
            
        # Call on_close callback
        self.on_close()
        
        # Close window
        self.root.destroy()

    def run(self):
        """Start the application"""
        self.root.mainloop()

# Example usage function
def on_capture_handler(filename):
    print(f"Photo captured and saved as: {filename}")
    # Here you would typically update your app state

def on_close_handler():
    print("Camera closed")
    # Here you would typically update your app state

# Example usage:
# camera = CameraCapture(on_capture_handler, on_close_handler, "Süden")
# camera.run()
