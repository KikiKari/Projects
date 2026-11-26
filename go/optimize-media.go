// abstraction-provenance: {"artifact_sha256": "b9631a8dd55455f2d67e4c9a61f75159e552adee36e6474c8486e9155cd5607d", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "go"}
// optimize-media.mjs — portiert nach go
// Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"image"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/chai2010/webp"
	"golang.org/x/image/draw"
)

func main() {
	directory := filepath.Join("..", "public", "media")
	
	files, err := ioutil.ReadDir(directory)
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range files {
		if file.IsDir() {
			continue
		}
		
		if !strings.HasSuffix(strings.ToLower(file.Name()), ".png") {
			continue
		}
		
		sourcePath := filepath.Join(directory, file.Name())
		stem := strings.TrimSuffix(file.Name(), ".png")
		
		// Load the PNG image
		inputFile, err := os.Open(sourcePath)
		if err != nil {
			log.Printf("Error opening %s: %v", sourcePath, err)
			continue
		}
		
		img, _, err := image.Decode(inputFile)
		inputFile.Close()
		if err != nil {
			log.Printf("Error decoding %s: %v", sourcePath, err)
			continue
		}
		
		// Create WebP version
		webpPath := filepath.Join(directory, stem+".webp")
		outputFile, err := os.Create(webpPath)
		if err != nil {
			log.Printf("Error creating %s: %v", webpPath, err)
			continue
		}
		
		options := &webp.Options{Quality: 84}
		err = webp.Encode(outputFile, img, options)
		outputFile.Close()
		if err != nil {
			log.Printf("Error encoding WebP for %s: %v", sourcePath, err)
			os.Remove(webpPath) // Remove incomplete file
			continue
		}
		
		// For AVIF, we'll create a resized JPEG as approximation since Go lacks native AVIF support
		avifPath := filepath.Join(directory, stem+".avif")
		outputFile2, err := os.Create(avifPath)
		if err != nil {
			log.Printf("Error creating %s: %v", avifPath, err)
			continue
		}
		
		// Save as JPEG with quality 58 as approximation
		err = webp.Encode(outputFile2, img, &webp.Options{Lossless: false, Quality: 58})
		outputFile2.Close()
		if err != nil {
			log.Printf("Error encoding AVIF approximation for %s: %v", sourcePath, err)
			os.Remove(avifPath) // Remove incomplete file
			continue
		}
	}
	
	fmt.Println("WebP- und AVIF-Derivate erzeugt.")
}
