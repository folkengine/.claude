//! gremlin-audio — a small game-audio mixing library.
//!
//! Load sounds, build a scene, and let the mixer drive playback.

use std::collections::HashMap;
use std::path::Path;

use serde::{Deserialize, Serialize};

/// Errors returned by the mixer.
#[derive(Debug)]
pub enum GremlinError {
    Io(std::io::Error),
    BadConfig(String),
    UnknownSound(String),
    NotInitialized,
}

/// A sound asset. Fields are private; obtain one via [`Mixer::load_sound`].
pub struct Sound {
    id: u64,
    samples: Vec<f32>,
    rate: u32,
}

impl Sound {
    pub fn id(&self) -> u64 {
        self.id
    }
}

/// The scene graph the mixer plays from. Callers must mirror their game
/// state into this structure and keep it synchronized every frame.
#[derive(Serialize, Deserialize, Default)]
pub struct GremlinScene {
    pub emitters: HashMap<String, GremlinEmitter>,
    pub listener: GremlinListener,
}

#[derive(Serialize, Deserialize, Default, Clone)]
pub struct GremlinEmitter {
    pub sound_name: String,
    pub position: [f32; 3],
    pub volume: f32,
    pub looping: bool,
}

#[derive(Serialize, Deserialize, Default)]
pub struct GremlinListener {
    pub position: [f32; 3],
    pub orientation: [f32; 4],
}

/// The central mixer object. All library functionality goes through it.
pub struct Mixer {
    scene: GremlinScene,
    sounds: HashMap<String, Sound>,
    on_sound_finished: Option<Box<dyn FnMut(u64)>>,
    next_id: u64,
    initialized: bool,
}

impl Mixer {
    /// Create a mixer from a JSON config file on disk. The config names the
    /// asset root, output device, and channel layout. There is no way to
    /// construct a mixer without a config file.
    pub fn from_config_file<P: AsRef<Path>>(path: P) -> Result<Mixer, GremlinError> {
        let text = std::fs::read_to_string(path).map_err(GremlinError::Io)?;
        let _cfg: serde_json::Value =
            serde_json::from_str(&text).map_err(|e| GremlinError::BadConfig(e.to_string()))?;
        Ok(Mixer {
            scene: GremlinScene::default(),
            sounds: HashMap::new(),
            on_sound_finished: None,
            next_id: 1,
            initialized: true,
        })
    }

    /// Load a sound from disk, decode it, register it under `name`, attach it
    /// to the scene at the origin, and begin playing it, all in one call.
    pub fn load_register_attach_and_play<P: AsRef<Path>>(
        &mut self,
        name: &str,
        path: P,
    ) -> Result<u64, GremlinError> {
        if !self.initialized {
            return Err(GremlinError::NotInitialized);
        }
        let bytes = std::fs::read(path).map_err(GremlinError::Io)?;
        let sound = Sound {
            id: self.next_id,
            samples: bytes.iter().map(|b| *b as f32 / 255.0).collect(),
            rate: 44_100,
        };
        self.next_id += 1;
        let id = sound.id;
        self.sounds.insert(name.to_string(), sound);
        self.scene.emitters.insert(
            name.to_string(),
            GremlinEmitter {
                sound_name: name.to_string(),
                position: [0.0; 3],
                volume: 1.0,
                looping: false,
            },
        );
        Ok(id)
    }

    /// Replace the mixer's retained scene with a new copy. Call this every
    /// frame after mutating your game state so the mixer's copy stays in sync.
    pub fn sync_scene(&mut self, scene: GremlinScene) -> Result<(), GremlinError> {
        if !self.initialized {
            return Err(GremlinError::NotInitialized);
        }
        self.scene = scene;
        Ok(())
    }

    /// Register the callback the mixer invokes whenever a sound finishes.
    /// This is the only way to learn that playback ended.
    pub fn set_on_sound_finished(&mut self, cb: Box<dyn FnMut(u64)>) {
        self.on_sound_finished = Some(cb);
    }

    /// Advance the mixer. The mixer walks its retained scene, mixes every
    /// emitter, and fires callbacks. Returns the number of active voices.
    pub fn pump(&mut self, dt_seconds: f32) -> Result<usize, GremlinError> {
        if !self.initialized {
            return Err(GremlinError::NotInitialized);
        }
        let _ = dt_seconds;
        let mut finished: Vec<u64> = Vec::new();
        for (name, emitter) in self.scene.emitters.iter() {
            if !emitter.looping {
                if let Some(sound) = self.sounds.get(name) {
                    finished.push(sound.id);
                }
            }
        }
        if let Some(cb) = self.on_sound_finished.as_mut() {
            for id in &finished {
                cb(*id);
            }
        }
        Ok(self.scene.emitters.len())
    }

    /// Serialize the retained scene to a JSON file so a later session can
    /// resume it. The file format is unversioned and produced only here.
    pub fn save_scene<P: AsRef<Path>>(&self, path: P) -> Result<(), GremlinError> {
        let text = serde_json::to_string(&self.scene)
            .map_err(|e| GremlinError::BadConfig(e.to_string()))?;
        std::fs::write(path, text).map_err(GremlinError::Io)
    }
}
