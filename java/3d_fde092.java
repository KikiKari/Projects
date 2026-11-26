// abstraction-provenance: {"artifact_sha256": "6945fc86f1baeca36bb7e305fe49b8c0bd7eb9c70c341897f1c967cda84e7a1f", "source_sha256": "fde0925c6da9f2674781482e5d06631c48818efbac6d63d45e764a139fc3bdf4", "target_language": "java"}
// 3d.html — portiert nach java
// Quelle: html, Projects@secret-vault-public:public/3d.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.nio.file.*;
import java.util.List;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class SecretVaultPublic extends JFrame {
    private static final String TITLE = "Secret-Vault Public — Interaktive Architektur";
    private static final String DESCRIPTION = "Vom Passwort zur verschlüsselten Datei — jede Schicht bleibt im Browser. Drehen, zoomen, Knoten auswählen.";
    
    // Farben
    private static final Color BG_COLOR = new Color(251, 250, 247);
    private static final Color PANEL_COLOR = Color.WHITE;
    private static final Color LINE_COLOR = new Color(230, 227, 220);
    private static final Color TEXT_COLOR = new Color(22, 25, 29);
    private static final Color MUTED_COLOR = new Color(95, 103, 115);
    private static final Color ACCENT_COLOR = new Color(91, 91, 214);
    private static final Color STAGE_COLOR = new Color(14, 20, 32);
    private static final Color STAGE_LINE_COLOR = new Color(29, 39, 57);
    
    // Dimensionen
    private static final int MIN_WIDTH = 800;
    private static final int MIN_HEIGHT = 600;
    
    // GUI-Komponenten
    private JPanel stagePanel;
    private JLabel nameLabel;
    private JLabel subtitleLabel;
    private JLabel layerLabel;
    private JLabel idLabel;
    private JButton prevButton;
    private JButton nextButton;
    private JLabel legendLabel;
    
    public SecretVaultPublic() {
        initializeUI();
    }
    
    private void initializeUI() {
        setTitle(TITLE);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setMinimumSize(new Dimension(MIN_WIDTH, MIN_HEIGHT));
        getContentPane().setBackground(BG_COLOR);
        
        // Hauptlayout
        setLayout(new BorderLayout());
        
        // Header-Bereich
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);
        
        // Hauptinhalt
        JPanel mainPanel = createMainPanel();
        add(mainPanel, BorderLayout.CENTER);
        
        // Footer
        JPanel footerPanel = createFooterPanel();
        add(footerPanel, BorderLayout.SOUTH);
        
        pack();
        setLocationRelativeTo(null);
    }
    
    private JPanel createHeaderPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(BG_COLOR);
        panel.setBorder(new EmptyBorder(20, 20, 10, 20));
        
        // Technik-Label
        JLabel techLabel = new JLabel("three.js · r128");
        techLabel.setFont(new Font("SansSerif", Font.BOLD, 12));
        techLabel.setForeground(ACCENT_COLOR);
        panel.add(techLabel, BorderLayout.NORTH);
        
        // Titel
        JLabel titleLabel = new JLabel("Secret-Vault Public");
        titleLabel.setFont(new Font("SansSerif", Font.PLAIN, 36));
        titleLabel.setForeground(TEXT_COLOR);
        panel.add(titleLabel, BorderLayout.CENTER);
        
        // Beschreibung
        JLabel descLabel = new JLabel(DESCRIPTION);
        descLabel.setFont(new Font("SansSerif", Font.PLAIN, 16));
        descLabel.setForeground(MUTED_COLOR);
        panel.add(descLabel, BorderLayout.SOUTH);
        
        return panel;
    }
    
    private JPanel createMainPanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBackground(BG_COLOR);
        panel.setBorder(new EmptyBorder(10, 20, 20, 20));
        
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.BOTH;
        gbc.weightx = 1.0;
        gbc.weighty = 1.0;
        
        // Bühnenbereich
        stagePanel = createStagePanel();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.weightx = 0.8;
        panel.add(stagePanel, gbc);
        
        // Kartenseite
        JPanel cardPanel = createCardPanel();
        gbc.gridx = 1;
        gbc.weightx = 0.2;
        panel.add(cardPanel, gbc);
        
        return panel;
    }
    
    private JPanel createStagePanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(STAGE_COLOR);
        panel.setPreferredSize(new Dimension(600, 400));
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(LINE_COLOR, 1),
            new EmptyBorder(10, 10, 10, 10)
        ));
        
        // Bühneninhalt (simuliert)
        JLabel stageContent = new JLabel("3D Visualisierung (simuliert)", SwingConstants.CENTER);
        stageContent.setForeground(Color.WHITE);
        stageContent.setFont(new Font("SansSerif", Font.BOLD, 18));
        panel.add(stageContent, BorderLayout.CENTER);
        
        // Steuerungsbuttons
        JPanel controlPanel = createControlPanel();
        panel.add(controlPanel, BorderLayout.NORTH);
        
        return panel;
    }
    
    private JPanel createControlPanel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        panel.setOpaque(false);
        
        JButton plusButton = new JButton("+");
        plusButton.setToolTipText("Näher");
        styleButton(plusButton);
        panel.add(plusButton);
        
        JButton minusButton = new JButton("−");
        minusButton.setToolTipText("Weiter weg");
        styleButton(minusButton);
        panel.add(minusButton);
        
        JButton resetButton = new JButton("Zurücksetzen");
        styleButton(resetButton);
        panel.add(resetButton);
        
        JButton isoButton = new JButton("Iso");
        isoButton.setToolTipText("Isometrisch oder perspektivisch");
        styleButton(isoButton);
        isoButton.setBackground(ACCENT_COLOR);
        isoButton.setForeground(Color.WHITE);
        panel.add(isoButton);
        
        return panel;
    }
    
    private void styleButton(JButton button) {
        button.setFont(new Font("SansSerif", Font.BOLD, 14));
        button.setBackground(PANEL_COLOR);
        button.setForeground(TEXT_COLOR);
        button.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(LINE_COLOR, 1),
            new EmptyBorder(5, 10, 5, 10)
        ));
    }
    
    private JPanel createCardPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(PANEL_COLOR);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(LINE_COLOR, 1),
            new EmptyBorder(15, 15, 15, 15)
        ));
        
        // Überschrift
        JLabel heading = new JLabel("Ausgewählter Knoten");
        heading.setFont(new Font("SansSerif", Font.BOLD, 11));
        heading.setForeground(MUTED_COLOR);
        heading.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.add(heading);
        
        panel.add(Box.createVerticalStrut(10));
        
        // Name
        nameLabel = new JLabel("—");
        nameLabel.setFont(new Font("SansSerif", Font.PLAIN, 23));
        nameLabel.setForeground(TEXT_COLOR);
        nameLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.add(nameLabel);
        
        // Untertitel
        subtitleLabel = new JLabel("Knoten anklicken oder durchblättern");
        subtitleLabel.setFont(new Font("SansSerif", Font.PLAIN, 14));
        subtitleLabel.setForeground(MUTED_COLOR);
        subtitleLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.add(subtitleLabel);
        
        panel.add(Box.createVerticalStrut(15));
        
        // Schicht-Feld
        JPanel layerField = createFieldPanel("Schicht", "—");
        layerLabel = (JLabel)((JPanel)layerField.getComponent(1)).getComponent(1);
        panel.add(layerField);
        
        panel.add(Box.createVerticalStrut(10));
        
        // ID-Feld
        JPanel idField = createFieldPanel("ID", "—");
        idLabel = (JLabel)((JPanel)idField.getComponent(1)).getComponent(1);
        panel.add(idField);
        
        panel.add(Box.createVerticalStrut(15));
        
        // Blättern-Buttons
        JPanel browsePanel = new JPanel(new GridLayout(1, 2, 5, 0));
        browsePanel.setOpaque(false);
        browsePanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 50));
        
        prevButton = new JButton("←\nVorheriger");
        prevButton.setFont(new Font("SansSerif", Font.BOLD, 12));
        prevButton.setVerticalTextPosition(SwingConstants.CENTER);
        prevButton.setHorizontalTextPosition(SwingConstants.CENTER);
        styleBrowseButton(prevButton);
        browsePanel.add(prevButton);
        
        nextButton = new JButton("Nächster\n→");
        nextButton.setFont(new Font("SansSerif", Font.BOLD, 12));
        nextButton.setVerticalTextPosition(SwingConstants.CENTER);
        nextButton.setHorizontalTextPosition(SwingConstants.CENTER);
        styleBrowseButton(nextButton);
        browsePanel.add(nextButton);
        
        panel.add(browsePanel);
        
        return panel;
    }
    
    private void styleBrowseButton(JButton button) {
        button.setBackground(PANEL_COLOR);
        button.setForeground(TEXT_COLOR);
        button.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(LINE_COLOR, 1),
            new EmptyBorder(10, 5, 10, 5)
        ));
    }
    
    private JPanel createFieldPanel(String label, String value) {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setOpaque(false);
        panel.setAlignmentX(Component.LEFT_ALIGNMENT);
        panel.setBorder(BorderFactory.createMatteBorder(1, 0, 0, 0, LINE_COLOR));
        panel.add(Box.createVerticalStrut(10));
        
        JPanel innerPanel = new JPanel(new BorderLayout());
        innerPanel.setOpaque(false);
        
        JLabel fieldLabel = new JLabel(label);
        fieldLabel.setFont(new Font("SansSerif", Font.BOLD, 11));
        fieldLabel.setForeground(MUTED_COLOR);
        innerPanel.add(fieldLabel, BorderLayout.NORTH);
        
        JLabel fieldValue = new JLabel(value);
        fieldValue.setFont(new Font("SansSerif", Font.BOLD, 14));
        fieldValue.setForeground(TEXT_COLOR);
        innerPanel.add(fieldValue, BorderLayout.CENTER);
        
        panel.add(innerPanel);
        
        return panel;
    }
    
    private JPanel createFooterPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.setBackground(BG_COLOR);
        panel.setBorder(new EmptyBorder(10, 20, 20, 20));
        
        // Legende
        legendLabel = new JLabel("Legende wird hier angezeigt");
        legendLabel.setFont(new Font("SansSerif", Font.PLAIN, 13));
        legendLabel.setForeground(MUTED_COLOR);
        panel.add(legendLabel, BorderLayout.NORTH);
        
        // Fußnote
        JLabel footerLabel = new JLabel(
            "Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. " +
            "Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und " +
            "rechnet danach ausschließlich lokal."
        );
        footerLabel.setFont(new Font("SansSerif", Font.PLAIN, 12));
        footerLabel.setForeground(MUTED_COLOR);
        footerLabel.setPreferredSize(new Dimension(800, 40));
        panel.add(footerLabel, BorderLayout.SOUTH);
        
        return panel;
    }
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeel());
            } catch (Exception e) {
                e.printStackTrace();
            }
            
            new SecretVaultPublic().setVisible(true);
        });
    }
}
