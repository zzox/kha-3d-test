const project = new Project('kha-3d-test');

project.addSources('src');
project.addShaders('shaders');
project.addAssets('assets/**');

resolve(project);
