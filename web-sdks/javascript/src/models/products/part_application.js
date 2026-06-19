/**
 * Part application models
 */

/**
 * Part application display
 */
export class PartApplicationDisplay {
  constructor({ name, value }) {
    this.name = name;
    this.value = value;
  }

  static fromJson(json) {
    return new PartApplicationDisplay({
      name: json.name,
      value: json.value,
    });
  }
}

/**
 * Part application
 */
export class PartApplication {
  constructor({ id, assets, displays }) {
    this.id = id;
    this.assets = assets;
    this.displays = displays;
  }

  static fromJson(json) {
    return new PartApplication({
      id: json.id,
      assets: json.assets || [],
      displays: (json.display || []).map(d => PartApplicationDisplay.fromJson(d)),
    });
  }
}
