package net.jangaroo.exml.model;

import net.jangaroo.exml.json.JsonObject;

import java.util.LinkedHashSet;
import java.util.Set;

public class ExmlModel {
  private String name;
  private String parentClassName;
  private Set<String> imports = new LinkedHashSet<String>();
  private JsonObject jsonObject = new JsonObject();

  public String getName() {
    return name;
  }

  public String getParentClassName() {
    return parentClassName;
  }

  public Set<String> getImports() {
    return imports;
  }

  public JsonObject getJsonObject() {
    return jsonObject;
  }

  public void setName(String name) {
    this.name = name;
  }

  public void setParentClassName(String parentClassName) {
    this.parentClassName = parentClassName;
    addImport(parentClassName);
  }

  public void addImport(String parentClassName) {
    imports.add(parentClassName);
  }
}