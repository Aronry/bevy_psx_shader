use bevy::prelude::*;
use bevy_psx::{camera::PsxCamera, material::{PsxDitherMaterial, PsxMaterial}, PsxPlugin};

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(ImagePlugin::default_nearest()))
    //    .add_plugins(DefaultPlugins)
        .add_plugins(PsxPlugin)
        .insert_resource(Msaa::Off)
        .add_systems(Startup,setup)
        .add_systems(Update,rotate)
        .add_systems(Update,blur)
        .run();
}


/// Set up a simple 3D scene
fn setup(
    mut commands: Commands,
    _meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<PsxMaterial>>,
    mut smaterials: ResMut<Assets<StandardMaterial>>,
    asset_server: Res<AssetServer>,
) {
    commands.spawn(PsxCamera::new(
        UVec2::new(1920 /4 , 1080 /4),
        None,
        Color::rgba(0.,0.,0.,0.),
        false,
        48.,
        45.,
        1
    ));
    let transform =
    Transform::from_scale(Vec3::splat(0.20)).with_translation(Vec3::new(0.0, -3.5, -10.0));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh2/Primitive0"),
            material: materials.add(PsxMaterial {
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh0/Primitive0"),
            material: materials.add(PsxMaterial {
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            //import from gltf dvaBlender.glb
            mesh: asset_server.load("dvaBlender.glb#Mesh1/Primitive0"),
            material: materials.add(PsxMaterial {
               // color_texture load from gltf
               // color_texture: Some(asset_server.load("crate.png")),
                color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                snap_amount: 10.0,  
                fog_distance: Vec2::new(250.0, 750.0), 
                
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));

/*     commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh2/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            mesh: asset_server.load("dvaBlender.glb#Mesh0/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    ));
    commands.spawn((
        MaterialMeshBundle {
            //import from gltf dvaBlender.glb
            mesh: asset_server.load("dvaBlender.glb#Mesh1/Primitive0"),
            material: smaterials.add(StandardMaterial {
                base_color_texture: Some(asset_server.load("dvaBlender.glb#Texture0")),
                ..Default::default()
            }),
            transform,
            ..default()
        },
        Rotates,
    )); */
    commands.spawn(PointLightBundle {
        transform: Transform::from_translation(Vec3::new(0.0, 0.0, 10.0)),
        ..default()
    });

}

#[derive(Component)]
struct Rotates;

/// Rotates any entity around the x and y axis
fn rotate(time: Res<Time>, mut query: Query<&mut Transform, With<Rotates>>) {
    for mut transform in &mut query {
        transform.rotate_y(0.95 * time.delta_seconds());
        // transform.scale = Vec3::splat(0.25);
        // transform.rotate_x(0.95 * time.delta_seconds());
        // transform.rotate_z(0.95 * time.delta_seconds());
    }
}

/// Rotates any entity around the x and y axis
fn blur(time: Res<Time>, mut mats: ResMut<Assets<PsxDitherMaterial>>) {
    for mut mat in mats.iter_mut() {
        mat.1.pixel_blur = time.elapsed_seconds().sin().max(0.) * 0.5;
        println!("{}", mat.1.pixel_blur);
    }
}
