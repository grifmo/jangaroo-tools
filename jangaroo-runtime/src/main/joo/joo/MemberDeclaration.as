package joo {

import joo.*;

public class MemberDeclaration {

  public static const
          METHOD_TYPE_GET : String = "get",
          METHOD_TYPE_SET : String = "set",
          MEMBER_TYPE_VAR : String = "var",
          MEMBER_TYPE_CONST : String = "const",
          MEMBER_TYPE_FUNCTION : String = "function",
          NAMESPACE_PRIVATE : String = "private",
          NAMESPACE_INTERNAL : String = "internal",
          NAMESPACE_PROTECTED : String = "protected",
          NAMESPACE_PUBLIC : String = "public",
          STATIC : String = "static",
          FINAL : String = "final",
          NATIVE : String = "native",
          BOUND : String = "bound",
          OVERRIDE : String = "override";

  private static var SUPPORTS_GETTERS_SETTERS : Boolean;
  private static var DEFINE_METHOD : Object;
  private static var LOOKUP_METHOD : Object;

{
  // no static initializers in system classes, use static block:
  SUPPORTS_GETTERS_SETTERS = "__defineGetter__" in Object.prototype;
  DEFINE_METHOD = {
    "get":  "__defineGetter__",
    "set": "__defineSetter__"
  };
  LOOKUP_METHOD = {
    "get": "__lookupGetter__",
    "set": "__lookupSetter__"
  };
}

  public static function create(memberDeclarationStr : String) : MemberDeclaration {
    var tokens : Array = memberDeclarationStr.split(/\s+/ as String) as Array;
    // ignore imports:
    return tokens[0] == "import" ? null
            : new MemberDeclaration(tokens);
  }

  internal var
          _namespace : String = "internal",
          _static : Boolean = false,
          _final : Boolean = false,
          _native : Boolean = false,
          _bound : Boolean = false,
          _override : Boolean = false,
          memberType : String,
          getterOrSetter : String,
          memberName : String,
          slot : String,
          value : *,
          _cloneFactory : Class;

  public function MemberDeclaration(tokens : Array) {
    for (var j:int = 0; j < tokens.length; ++j) {
      var token : String = tokens[j];
      if (!this.memberType) {
        switch (token) {
          case STATIC:
          case FINAL:
          case NATIVE:
          case BOUND:
          case OVERRIDE:
            this["_" + token] = true; break;
          case MEMBER_TYPE_VAR:
          case MEMBER_TYPE_CONST:
          case MEMBER_TYPE_FUNCTION:
            this.memberType = token; break;
          default:
            // "private", "public", "protected", "internal" or a custom namespace:
            this._namespace = token;
        }
      } else {
        if (this.isMethod() && LOOKUP_METHOD[this.memberName]) {
          this.getterOrSetter = this.memberName; // detected getter or setter
        }
        this.memberName = token; // token following the member type is the member name
      }
    }
    if (!this.memberType) {
      throw new Error("Missing member type in declaration '" + tokens.join(" ") + "'.");
    }
  }

  public function getQualifiedName() : String {
    return this._namespace + "::" + this.memberName;
  }

  public function isPrivate() : Boolean {
    return this._namespace == NAMESPACE_PRIVATE;
  }

  public function isStatic() : Boolean {
    return this._static;
  }

  public function isFinal() : Boolean {
    return this._final;
  }

  public function isNative() : Boolean {
    return this._native;
  }

  public function isOverride() : Boolean {
    return this._override;
  }

  public function isBound() : Boolean {
    return this._bound;
  }

  public function isMethod() : Boolean {
    return this.memberType == MEMBER_TYPE_FUNCTION;
  }

  // public function retrieveMember(source : Object) : Function
  /* not needed if we take reflection seriously!
   retrieveMember: function joo$MemberDeclaration$getMember(source) {
   return this.getterOrSetter==METHOD_TYPE_GET ? source.__lookupGetter__(this.memberName)
   : this.getterOrSetter==METHOD_TYPE_SET ? source.__lookupSetter__(this.memberName)
   : source[this.memberName];
   },*/

  internal function getNativeMember(publicConstructor : Class) : * {
    var target : * = this.isStatic() ? publicConstructor : publicConstructor.prototype;
    if (this.memberType == MEMBER_TYPE_FUNCTION && this.getterOrSetter) {
      // native variables are only declared as getter/setter functions, never implemented as such:
      this.memberType = MEMBER_TYPE_VAR;
      this.getterOrSetter = null;
    }
    try {
      var member : * = target[this.memberName];
    } catch (e : Error) {
      // ignore Firefox' native member access exceptions.
    }
    if (typeof member != "function") {
      var memberObject : Object = {};
      memberObject[this.memberName] = member;
      member = memberObject;
    }
    return member;
  }

  internal function hasOwnMember(target : Object) : Boolean {
    // fast path:
    if (!this.getterOrSetter && target.hasOwnProperty) {
      return target.hasOwnProperty(this.slot);
    }
    var value : * = this.retrieveMember(target);
    if (value !== undefined) {
      // is it really target's own member? Retrieve super's value:
      var superTarget : Object = target.constructor.prototype;
      var superValue : * = this.retrieveMember(superTarget);
      if (value !== superValue) {
        return true;
      }
    }
    return false;
  }

  internal function retrieveMember(target : Object) : * {
    if (!target) {
      return undefined;
    }
    var slot : String = this.slot;
    if (this.getterOrSetter) {
      if (SUPPORTS_GETTERS_SETTERS) {
        return target[LOOKUP_METHOD[this.getterOrSetter]](slot);
      } else {
        slot = this.getterOrSetter + "$" + slot;
      }
    }
    return target[slot];
  }

  internal function storeMember(target : Object) : void {
    // store only if not native:
    if (!this.isNative()) {
      var slot : String = this.slot;
      if (this.getterOrSetter) {
        if (SUPPORTS_GETTERS_SETTERS) {
          // defining a getter or setter disables the counterpart setter/getter from the prototype,
          // so copy that setter/getter before, if "target" does not already define it:
          var oppositeMethodType:* = this.getterOrSetter == METHOD_TYPE_GET ? METHOD_TYPE_SET : METHOD_TYPE_GET;
          var counterpart : Function = target[LOOKUP_METHOD[oppositeMethodType]](slot);
          // if counterpart is defined, check that it is not overridden (differs from prototype's counterpart):
          if (counterpart && counterpart === target.constructor.prototype[LOOKUP_METHOD[oppositeMethodType]](slot)) {
            // set the counterpart directly on target. This may be redundant, but we cannot find out.
            target[DEFINE_METHOD[oppositeMethodType]](slot, counterpart);
          }
          target[DEFINE_METHOD[this.getterOrSetter]](slot, this.value);
          return;
        } else {
          slot = this.getterOrSetter + "$" + slot;
        }
      }
      target[slot] = this.value;
    }
  }

  public function hasInitializer() : Boolean {
    return this.memberType != MEMBER_TYPE_FUNCTION && typeof this.value == "function" && this.value.constructor !== RegExp;
  }

  public function _getCloneFactory() : Class {
    if (!this._cloneFactory) {
      this._cloneFactory = function() : void {
      };
      this._cloneFactory.prototype = this;
    }
    return this._cloneFactory;
  }

  public function clone(changedProperties : Object) : MemberDeclaration {
    var CloneFactory : Class = this._getCloneFactory();
    var clone : MemberDeclaration = new CloneFactory();
    for (var m:String in changedProperties) {
      clone[m] = changedProperties[m];
    }
    return clone;
  }

  public function toString() : String {
    var sb : Array = [this._namespace];
    if (this._static) {
      sb.push(STATIC);
    }
    if (this._override) {
      sb.push(OVERRIDE);
    }
    if (this._bound) {
      sb.push(BOUND);
    }
    sb.push(this.memberType);
    if (this.getterOrSetter) {
      sb.push(this.getterOrSetter);
    }
    sb.push(this.memberName);
    return sb.join(" ");
  }

}
}