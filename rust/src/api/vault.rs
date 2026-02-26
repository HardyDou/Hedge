use rand::RngCore;
use crate::api::model::{Vault, VaultItem};
use crate::api::crypto::{derive_key, encrypt, decrypt};
use anyhow::{Context, Result};
use secrecy::Secret;
use std::fs;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct EncryptedVault {
    pub salt: [u8; 16],
    pub nonce: [u8; 12],
    pub ciphertext: Vec<u8>,
}

pub fn save_vault(path: String, master_password: String, vault: Vault) -> Result<()> {
    let master_password = Secret::new(master_password);
    let mut salt = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut salt);
    
    let key = derive_key(&master_password, &salt)?;
    let vault_json = serde_json::to_vec(&vault)?;
    
    let (ciphertext, nonce) = encrypt(&vault_json, &key)?;
    
    let encrypted = EncryptedVault {
        salt,
        nonce,
        ciphertext,
    };
    
    let data = serde_json::to_vec(&encrypted)?;
    fs::write(path, data).context("Failed to write vault file")?;
    
    Ok(())
}

pub fn load_vault(path: String, master_password: String) -> Result<Vault> {
    let master_password = Secret::new(master_password);
    let data = fs::read(path).context("Failed to read vault file")?;
    
    let encrypted: EncryptedVault = serde_json::from_slice(&data).context("Failed to parse encrypted vault")?;
    
    let key = derive_key(&master_password, &encrypted.salt)?;
    let plaintext = decrypt(&encrypted.ciphertext, &key, &encrypted.nonce)?;
    
    let vault: Vault = serde_json::from_slice(&plaintext).context("Failed to parse vault plaintext")?;
    
    Ok(vault)
}

pub fn create_empty_vault() -> Vault {
    Vault::default()
}

pub fn add_item(mut vault: Vault, title: String) -> Vault {
    let item = VaultItem::new(title);
    vault.items.push(item);
    vault
}

pub fn update_item(mut vault: Vault, updated_item: VaultItem) -> Vault {
    if let Some(index) = vault.items.iter().position(|i| i.id == updated_item.id) {
        vault.items[index] = updated_item;
    }
    vault
}

pub fn delete_item(mut vault: Vault, id: String) -> Vault {
    vault.items.retain(|i| i.id != id);
    vault
}
