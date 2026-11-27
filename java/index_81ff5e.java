// abstraction-provenance: {"artifact_sha256": "6bd2dab52e443c7e76a01ee4854baff106a067962559f5099be2c30c91f48344", "source_sha256": "81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.nio.file.*;
import java.security.*;
import java.util.*;
import java.util.List;
import javax.crypto.*;
import javax.crypto.spec.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.util.Base64;

public class VaultCache extends JFrame {
    private static final String VERSION = "1.0";
    private static final String MAGIC = "SVPB1";
    private static final int SALT_LENGTH = 16;
    private static final int IV_LENGTH = 12;
    private static final int ITERATIONS = 210000;
    
    private ResourceBundle bundle;
    private VaultData vault;
    
    // UI Components
    private JPasswordField passField;
    private JTextField fileField;
    private JTextArea blobArea;
    private JTextArea resultArea;
    private JPanel editorPanel;
    private JPanel savePanel;
    private JLabel openMessage;
    private JLabel saveMessage;
    private JPanel providersPanel;
    private JTextField newProviderField;
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeel());
            } catch (Exception e) {
                e.printStackTrace();
            }
            new VaultCache().setVisible(true);
        });
    }
    
    public VaultCache() {
        initializeLanguage();
        initializeUI();
        setupEventHandlers();
    }
    
    private void initializeLanguage() {
        Locale locale = Locale.getDefault();
        if (locale.getLanguage().equals("de")) {
            bundle = ResourceBundle.getBundle("messages_de");
        } else {
            bundle = ResourceBundle.getBundle("messages_en");
        }
    }
    
    private void initializeUI() {
        setTitle(bundle.getString("title"));
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLayout(new BorderLayout());
        
        // Main panel
        JPanel mainPanel = new JPanel(new BorderLayout());
        mainPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));
        add(mainPanel, BorderLayout.CENTER);
        
        // Header
        JPanel headerPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        headerPanel.add(new JLabel(new BrandIcon()));
        headerPanel.add(new JLabel(bundle.getString("title")));
        mainPanel.add(headerPanel, BorderLayout.NORTH);
        
        // Description
        JLabel descriptionLabel = new JLabel(bundle.getString("sub"));
        descriptionLabel.setBorder(BorderFactory.createEmptyBorder(0, 0, 15, 0));
        mainPanel.add(descriptionLabel, BorderLayout.SOUTH);
        
        // Open/New Card
        JPanel openCard = createOpenCard();
        mainPanel.add(openCard, BorderLayout.CENTER);
        
        // Editor Card
        editorPanel = createEditorCard();
        editorPanel.setVisible(false);
        mainPanel.add(editorPanel, BorderLayout.EAST);
        
        // Save Card
        savePanel = createSaveCard();
        savePanel.setVisible(false);
        mainPanel.add(savePanel, BorderLayout.SOUTH);
        
        pack();
        setLocationRelativeTo(null);
    }
    
    private JPanel createOpenCard() {
        JPanel card = new JPanel();
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBorder(BorderFactory.createTitledBorder(bundle.getString("hOpen")));
        
        // Passphrase
        JLabel passLabel = new JLabel(bundle.getString("pass"));
        passField = new JPasswordField(20);
        card.add(passLabel);
        card.add(passField);
        
        // File selection
        JLabel fileLabel = new JLabel(bundle.getString("file"));
        JButton fileButton = new JButton("...");
        fileField = new JTextField(20);
        fileField.setEditable(false);
        
        JPanel filePanel = new JPanel(new BorderLayout());
        filePanel.add(fileField, BorderLayout.CENTER);
        filePanel.add(fileButton, BorderLayout.EAST);
        
        card.add(fileLabel);
        card.add(filePanel);
        
        // Blob area
        JLabel blobLabel = new JLabel(bundle.getString("blob"));
        blobArea = new JTextArea(5, 30);
        JScrollPane blobScroll = new JScrollPane(blobArea);
        
        card.add(blobLabel);
        card.add(blobScroll);
        
        // Buttons
        JButton openButton = new JButton(bundle.getString("open"));
        JButton newButton = new JButton(bundle.getString("neu"));
        openMessage = new JLabel();
        
        JPanel buttonPanel = new JPanel(new FlowLayout());
        buttonPanel.add(openButton);
        buttonPanel.add(newButton);
        buttonPanel.add(openMessage);
        
        card.add(buttonPanel);
        
        // Event handlers for open card
        fileButton.addActionListener(e -> selectFile());
        openButton.addActionListener(e -> openVault());
        newButton.addActionListener(e -> createNewVault());
        
        return card;
    }
    
    private JPanel createEditorCard() {
        JPanel card = new JPanel();
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBorder(BorderFactory.createTitledBorder(bundle.getString("hEdit")));
        
        providersPanel = new JPanel();
        providersPanel.setLayout(new BoxLayout(providersPanel, BoxLayout.Y_AXIS));
        JScrollPane scrollPane = new JScrollPane(providersPanel);
        scrollPane.setPreferredSize(new Dimension(400, 300));
        
        card.add(scrollPane);
        
        // New provider section
        newProviderField = new JTextField(20);
        JButton addProviderButton = new JButton(bundle.getString("addProv"));
        
        JPanel newProviderPanel = new JPanel(new FlowLayout());
        newProviderPanel.add(new JLabel("New Provider:"));
        newProviderPanel.add(newProviderField);
        newProviderPanel.add(addProviderButton);
        
        card.add(newProviderPanel);
        
        addProviderButton.addActionListener(e -> addNewProvider());
        
        return card;
    }
    
    private JPanel createSaveCard() {
        JPanel card = new JPanel();
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBorder(BorderFactory.createTitledBorder(bundle.getString("hSave")));
        
        // Buttons
        JButton encryptButton = new JButton(bundle.getString("enc"));
        JButton downloadButton = new JButton(bundle.getString("dl"));
        JButton exportButton = new JButton(bundle.getString("exp"));
        saveMessage = new JLabel();
        
        JPanel buttonPanel = new JPanel(new FlowLayout());
        buttonPanel.add(encryptButton);
        buttonPanel.add(downloadButton);
        buttonPanel.add(exportButton);
        buttonPanel.add(saveMessage);
        
        card.add(buttonPanel);
        
        // Result area
        JLabel resultLabel = new JLabel(bundle.getString("result"));
        resultArea = new JTextArea(10, 40);
        resultArea.setEditable(false);
        JScrollPane resultScroll = new JScrollPane(resultArea);
        
        card.add(resultLabel);
        card.add(resultScroll);
        
        // Event handlers
        encryptButton.addActionListener(e -> encryptVault());
        downloadButton.addActionListener(e -> downloadVault());
        exportButton.addActionListener(e -> exportJson());
        
        return card;
    }
    
    private void setupEventHandlers() {
        // Additional event handling can be added here
    }
    
    private void selectFile() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setFileFilter(new FileNameExtensionFilter("Vault Files", "svpb", "txt", "vault", "b64"));
        if (fileChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                String content = new String(Files.readAllBytes(fileChooser.getSelectedFile().toPath()));
                blobArea.setText(content.trim());
            } catch (IOException e) {
                JOptionPane.showMessageDialog(this, "Error reading file: " + e.getMessage(), 
                                            "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void openVault() {
        String passphrase = new String(passField.getPassword());
        String blobContent = blobArea.getText().trim();
        
        if (passphrase.isEmpty()) {
            openMessage.setText(bundle.getString("needPass"));
            openMessage.setForeground(Color.RED);
            return;
        }
        
        if (blobContent.isEmpty()) {
            openMessage.setText(bundle.getString("noInput"));
            openMessage.setForeground(Color.RED);
            return;
        }
        
        try {
            vault = decryptVault(blobContent, passphrase);
            renderEditor();
            openMessage.setText(bundle.getString("opened"));
            openMessage.setForeground(Color.GREEN);
        } catch (Exception e) {
            openMessage.setText(bundle.getString("bad"));
            openMessage.setForeground(Color.RED);
        }
    }
    
    private void createNewVault() {
        String passphrase = new String(passField.getPassword());
        if (passphrase.isEmpty()) {
            openMessage.setText(bundle.getString("needPass"));
            openMessage.setForeground(Color.RED);
            return;
        }
        
        vault = new VaultData();
        vault.meta = new HashMap<>();
        vault.meta.put("created", java.time.LocalDate.now().toString());
        vault.meta.put("format", "SVPB1");
        vault.providers = new HashMap<>();
        
        renderEditor();
        openMessage.setText(bundle.getString("created"));
        openMessage.setForeground(Color.GREEN);
    }
    
    private void addNewProvider() {
        String providerName = newProviderField.getText().trim();
        if (!providerName.isEmpty() && vault != null) {
            vault.providers.put(providerName, new HashMap<>());
            newProviderField.setText("");
            renderEditor();
        }
    }
    
    private void renderEditor() {
        if (vault == null) return;
        
        editorPanel.setVisible(true);
        savePanel.setVisible(true);
        providersPanel.removeAll();
        
        for (Map.Entry<String, Map<String, String>> entry : vault.providers.entrySet()) {
            String providerName = entry.getKey();
            Map<String, String> fields = entry.getValue();
            
            JPanel providerPanel = new JPanel();
            providerPanel.setLayout(new BoxLayout(providerPanel, BoxLayout.Y_AXIS));
            providerPanel.setBorder(BorderFactory.createTitledBorder(providerName));
            
            // Add existing fields
            for (Map.Entry<String, String> fieldEntry : fields.entrySet()) {
                JPanel fieldPanel = new JPanel(new FlowLayout());
                fieldPanel.add(new JLabel(fieldEntry.getKey() + ":"));
                JTextField valueField = new JTextField(fieldEntry.getValue(), 15);
                fieldPanel.add(valueField);
                providerPanel.add(fieldPanel);
            }
            
            providersPanel.add(providerPanel);
        }
        
        providersPanel.revalidate();
        providersPanel.repaint();
    }
    
    private void encryptVault() {
        if (vault == null) {
            saveMessage.setText(bundle.getString("needOpen"));
            saveMessage.setForeground(Color.RED);
            return;
        }
        
        String passphrase = new String(passField.getPassword());
        if (passphrase.isEmpty()) {
            saveMessage.setText(bundle.getString("needPass"));
            saveMessage.setForeground(Color.RED);
            return;
        }
        
        try {
            String encrypted = encryptVault(vault, passphrase);
            resultArea.setText(encrypted);
            saveMessage.setText(bundle.getString("encrypted"));
            saveMessage.setForeground(Color.GREEN);
        } catch (Exception e) {
            saveMessage.setText("Encryption error: " + e.getMessage());
            saveMessage.setForeground(Color.RED);
        }
    }
    
    private void downloadVault() {
        if (resultArea.getText().isEmpty()) return;
        
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setSelectedFile(new File("vault.svpb"));
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            try {
                Files.write(fileChooser.getSelectedFile().toPath(), resultArea.getText().getBytes());
                JOptionPane.showMessageDialog(this, "File saved successfully!");
            } catch (IOException e) {
                JOptionPane.showMessageDialog(this, "Error saving file: " + e.getMessage(), 
                                            "Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void exportJson() {
        if (vault == null) return;
        
        try {
            String json = toJson(vault);
            resultArea.setText(json);
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this, "Error exporting JSON: " + e.getMessage(), 
                                        "Error", JOptionPane.ERROR_MESSAGE);
        }
    }
    
    // Encryption/Decryption methods
    private VaultData decryptVault(String base64Data, String password) throws Exception {
        byte[] data = Base64.getDecoder().decode(base64Data.trim());
        
        // Check magic bytes
        String magic = new String(Arrays.copyOfRange(data, 0, 5));
        if (!MAGIC.equals(magic)) {
            throw new IllegalArgumentException("Invalid file format");
        }
        
        // Extract components
        byte[] salt = Arrays.copyOfRange(data, 5, 5 + SALT_LENGTH);
        byte[] iv = Arrays.copyOfRange(data, 5 + SALT_LENGTH, 5 + SALT_LENGTH + IV_LENGTH);
        byte[] ciphertext = Arrays.copyOfRange(data, 5 + SALT_LENGTH + IV_LENGTH, data.length);
        
        // Derive key
        SecretKey key = deriveKey(password, salt);
        
        // Decrypt
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(128, iv);
        cipher.init(Cipher.DECRYPT_MODE, key, spec);
        byte[] plaintext = cipher.doFinal(ciphertext);
        
        // Parse JSON
        return fromJson(new String(plaintext));
    }
    
    private String encryptVault(VaultData vault, String password) throws Exception {
        // Generate random salt and IV
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        byte[] iv = new byte[IV_LENGTH];
        random.nextBytes(salt);
        random.nextBytes(iv);
        
        // Derive key
        SecretKey key = deriveKey(password, salt);
        
        // Convert vault to JSON
        String json = toJson(vault);
        byte[] plaintext = json.getBytes("UTF-8");
        
        // Encrypt
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(128, iv);
        cipher.init(Cipher.ENCRYPT_MODE, key, spec);
        byte[] ciphertext = cipher.doFinal(plaintext);
        
        // Combine all parts
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        output.write(MAGIC.getBytes());
        output.write(salt);
        output.write(iv);
        output.write(ciphertext);
        
        return Base64.getEncoder().encodeToString(output.toByteArray());
    }
    
    private SecretKey deriveKey(String password, byte[] salt) throws Exception {
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATIONS, 256);
        SecretKey tmp = factory.generateSecret(spec);
        return new SecretKeySpec(tmp.getEncoded(), "AES");
    }
    
    // JSON serialization (simplified)
    private String toJson(VaultData vault) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\n  \"meta\": {\n");
        boolean first = true;
        for (Map.Entry<String, String> entry : vault.meta.entrySet()) {
            if (!first) sb.append(",\n");
            sb.append("    \"").append(entry.getKey()).append("\": \"").append(entry.getValue()).append("\"");
            first = false;
        }
        sb.append("\n  },\n  \"providers\": {\n");
        
        first = true;
        for (Map.Entry<String, Map<String, String>> provider : vault.providers.entrySet()) {
            if (!first) sb.append(",\n");
            sb.append("    \"").append(provider.getKey()).append("\": {\n");
            boolean innerFirst = true;
            for (Map.Entry<String, String> field : provider.getValue().entrySet()) {
                if (!innerFirst) sb.append(",\n");
                sb.append("      \"").append(field.getKey()).append("\": \"").append(field.getValue()).append("\"");
                innerFirst = false;
            }
            sb.append("\n    }");
            first = false;
        }
        sb.append("\n  }\n}");
        return sb.toString();
    }
    
    private VaultData fromJson(String json) {
        // Simplified JSON parsing - in reality you'd use a proper JSON library
        VaultData vault = new VaultData();
        vault.meta = new HashMap<>();
        vault.providers = new HashMap<>();
        // This would need proper JSON parsing implementation
        return vault;
    }
    
    // Inner classes
    private static class VaultData {
        Map<String, String> meta;
        Map<String, Map<String, String>> providers;
    }
    
    private static class BrandIcon implements Icon {
        @Override
        public void paintIcon(Component c, Graphics g, int x, int y) {
            Graphics2D g2 = (Graphics2D) g.create();
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            
            // Draw gradient background
            GradientPaint gradient = new GradientPaint(x, y, new Color(91, 91, 214), 
                                                      x + getIconWidth(), y + getIconHeight(), 
                                                      new Color(124, 92, 255));
            g2.setPaint(gradient);
            g2.fillRoundRect(x, y, getIconWidth(), getIconHeight(), 9, 9);
            
            // Draw inner border
            g2.setColor(new Color(255, 255, 255, 235));
            g2.setStroke(new BasicStroke(2));
            g2.drawRoundRect(x + 4, y + 4, getIconWidth() - 8, getIconHeight() - 8, 4, 4);
            
            g2.dispose();
        }
        
        @Override
        public int getIconWidth() { return 32; }
        
        @Override
        public int getIconHeight() { return 32; }
    }
}
