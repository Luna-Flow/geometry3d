pub struct SceneObject {
  mesh : @core.Mesh
  transform : @core.Transform3
}

pub struct Light {
  direction : @la.Vector[Double]
}

pub struct Scene {
  objects : Array[SceneObject]
  light : Light
}

pub fn SceneObject::new(mesh : @core.Mesh, transform : @core.Transform3) -> SceneObject {
  { mesh, transform }
}

pub fn Light::directional(direction : @la.Vector[Double]) -> Light {
  { direction: @core.normalize_vec(direction) }
}

pub fn Light::default() -> Light {
  Light::directional(@core.vec3(0.6, 0.7, -1.0))
}

pub fn Scene::new(light : Light) -> Scene {
  { objects: [], light }
}

pub fn Scene::single(mesh : @core.Mesh, transform : @core.Transform3, light : Light) -> Scene {
  { objects: [{ mesh, transform }], light }
}

pub fn Scene::add_object(self : Scene, object : SceneObject) -> Unit {
  self.objects.push(object)
}
