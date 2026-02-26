use serde::{Deserialize, Serialize};
use uuid::Uuid;
use zeroize::Zeroize;

#[derive(Serialize, Deserialize, Clone, Debug, Zeroize)]
pub struct Attachment {
    pub name: String,
    pub data: Vec<u8>,
}

#[derive(Serialize, Deserialize, Clone, Debug, Zeroize)]
pub struct VaultItem {
    pub id: String,
    pub title: String,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub category: Option<String>,
    pub attachments: Vec<Attachment>,
    pub updated_at: i64,
}

impl VaultItem {
    pub fn new(title: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            title,
            username: None,
            password: None,
            url: None,
            notes: None,
            category: None,
            attachments: Vec::new(),
            updated_at: chrono::Utc::now().timestamp(),
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct Vault {
    pub items: Vec<VaultItem>,
    pub version: u32,
}

impl Default for Vault {
    fn default() -> Self {
        Self {
            items: Vec::new(),
            version: 1,
        }
    }
}
