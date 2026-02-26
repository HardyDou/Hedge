use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use argon2::{
    password_hash::{PasswordHasher, SaltString},
    Argon2,
};
use rand::RngCore;
use secrecy::{ExposeSecret, Secret};
use anyhow::{Context, Result};

pub(crate) fn derive_key(password: &Secret<String>, salt: &[u8]) -> Result<[u8; 32]> {
    let mut key = [0u8; 32];
    let argon2 = Argon2::default();
    
    let salt_str = SaltString::encode_b64(salt).map_err(|e| anyhow::anyhow!(e.to_string()))?;
    let hash = argon2.hash_password(password.expose_secret().as_bytes(), &salt_str)
        .map_err(|e| anyhow::anyhow!(e.to_string()))?;
    
    let hash_bytes = hash.hash.context("Failed to get hash bytes")?;
    
    // Ensure we take 32 bytes for AES-256
    if hash_bytes.len() >= 32 {
        key.copy_from_slice(&hash_bytes.as_bytes()[..32]);
    } else {
        return Err(anyhow::anyhow!("Derived key too short"));
    }
    
    Ok(key)
}

pub(crate) fn encrypt(data: &[u8], key: &[u8; 32]) -> Result<(Vec<u8>, [u8; 12])> {

    let cipher = Aes256Gcm::new(key.into());
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);
    
    let ciphertext = cipher.encrypt(nonce, data)
        .map_err(|e| anyhow::anyhow!("Encryption failure: {}", e))?;
    
    Ok((ciphertext, nonce_bytes))
}

pub(crate) fn decrypt(ciphertext: &[u8], key: &[u8; 32], nonce_bytes: &[u8; 12]) -> Result<Vec<u8>> {
    let cipher = Aes256Gcm::new(key.into());
    let nonce = Nonce::from_slice(nonce_bytes);
    
    let plaintext = cipher.decrypt(nonce, ciphertext)
        .map_err(|e| anyhow::anyhow!("Decryption failure: {}", e))?;
    
    Ok(plaintext)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encryption_decryption() -> Result<()> {
        let password = Secret::new("strong_password".to_string());
        let salt = [1u8; 16];
        let data = b"sensitive data";
        
        let key = derive_key(&password, &salt)?;
        let (ciphertext, nonce) = encrypt(data, &key)?;
        let decrypted = decrypt(&ciphertext, &key, &nonce)?;
        
        assert_eq!(data.to_vec(), decrypted);
        Ok(())
    }

    #[test]
    fn test_wrong_password() -> Result<()> {
        let password = Secret::new("strong_password".to_string());
        let wrong_password = Secret::new("wrong_password".to_string());
        let salt = [1u8; 16];
        let data = b"sensitive data";
        
        let key = derive_key(&password, &salt)?;
        let wrong_key = derive_key(&wrong_password, &salt)?;
        
        let (ciphertext, nonce) = encrypt(data, &key)?;
        let result = decrypt(&ciphertext, &wrong_key, &nonce);
        
        assert!(result.is_err());
        Ok(())
    }
}
