use bevy::{
    prelude::*,
    reflect::TypeUuid,
    reflect::TypePath,
    render::render_resource::{AsBindGroup, ShaderRef},
    sprite::Material2d,
};

pub const PSX_FRAG_SHADER_HANDLE: HandleUntyped =
    HandleUntyped::weak_from_u64(Shader::TYPE_UUID, 310591614790536);
pub const PSX_DITH_SHADER_HANDLE: HandleUntyped =
    HandleUntyped::weak_from_u64(Shader::TYPE_UUID, 210541614790536);
pub const PSX_DITHER_HANDLE: HandleUntyped =
    HandleUntyped::weak_from_u64(Image::TYPE_UUID, 510291613494514);
pub const PSX_VERT_SHADER_HANDLE: HandleUntyped =
    HandleUntyped::weak_from_u64(Shader::TYPE_UUID, 120592519790135);

impl Material for PsxMaterial {
    fn fragment_shader() -> ShaderRef {
        PSX_FRAG_SHADER_HANDLE.typed().into()
    }

    fn vertex_shader() -> ShaderRef {
        PSX_VERT_SHADER_HANDLE.typed().into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        self.alpha_mode
    }
}


impl Material2d for PsxDitherMaterial {
    fn fragment_shader() -> ShaderRef {
        PSX_DITH_SHADER_HANDLE.typed().into()
    }
}

// This is the struct that will be passed to your shader
#[derive(AsBindGroup, TypeUuid, TypePath, Debug, Clone)]
#[uuid = "fe8315d8-1757-4cad-9a86-2a358cba2507"]
pub struct PsxMaterial {
    #[uniform(0)]
    pub color: Color,
    #[uniform(0)]
    pub fog_color: Color,
    #[uniform(0)]
    pub snap_amount: f32,
    #[uniform(0)]
    pub fog_distance: Vec2,
    // #[uniform(0)]
    // pub dither_amount: f32,
    // #[uniform(0)]
    // pub banding_enabled: u32,
    /// First one is start second is end
    #[texture(1)]
    #[sampler(2)]
    pub color_texture: Option<Handle<Image>>,
    pub alpha_mode: AlphaMode,
    // #[texture(3)]
    // #[sampler(4, sampler_type = "non_filtering")]
    // pub dither_color_texture: Option<Handle<Image>>,
}

impl Default for PsxMaterial {
    fn default() -> Self {
        Self {
            color: Color::WHITE,
            fog_color: Color::WHITE,
            snap_amount: 5.0,
            fog_distance: Vec2::new(25.0, 75.0),
            // dither_amount: 64.0,
            color_texture: None,
            alpha_mode: AlphaMode::Opaque,
            // dither_color_texture: Some(PSX_DITHER_HANDLE.typed()),
            // banding_enabled: 0,
        }
    }
}

#[derive(AsBindGroup, TypeUuid, TypePath, Debug, Clone)]
#[uuid = "fe4315d8-1757-4cad-9a86-2a358cba2507"]
pub struct PsxDitherMaterial {
    #[uniform(0)]
    pub dither_amount: f32,
    #[uniform(0)]
    pub banding_enabled: u32,

    #[texture(1)]
    #[sampler(2)]
    pub color_texture: Option<Handle<Image>>,

    /// First one is start second is end
    #[texture(3)]
    // #[sampler(4, sampler_type = "non_filtering")]
    #[sampler(4)]
    pub dither_color_texture: Option<Handle<Image>>,
}

impl Default for PsxDitherMaterial {
    fn default() -> Self {
        Self {
            dither_amount: 48.0,
            dither_color_texture: Some(PSX_DITHER_HANDLE.typed()),
            banding_enabled: 1,
            color_texture: None,
        }
    }
}
