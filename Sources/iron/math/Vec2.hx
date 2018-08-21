package iron.math;

import kha.FastFloat;

class Vec2 {
	public var x:FastFloat;
	public var y:FastFloat;

	inline public function new(x:FastFloat = 0.0, y:FastFloat = 0.0) {
		this.x = x;
		this.y = y;
	}

	inline public function cross(v:Vec2):FastFloat {
		return x * v.y - y * v.x;
	}
	
	inline public function set(x:FastFloat, y:FastFloat):Vec2{
		this.x = x;
		this.y = y;
		return this;
	}

	inline public function add(v:Vec2):Vec2 {
		x += v.x;
		y += v.y;
		return this;
	}

	inline public function addf(x:FastFloat, y:FastFloat):Vec2 {
		this.x += x;
		this.y += y;
		return this;
	}

	inline public function addvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x + b.x;
		y = a.y + b.y;
		return this;
	}

	inline public function subvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x - b.x;
		y = a.y - b.y;
		return this;
	}

	inline public function normalize():Vec2 {
		var a = this.x;
        var b = this.y;
        var l = a * a + b * b;
        if(l > 0.0) {
            l = 1.0 / Math.sqrt(l);
            this.x = a * l;
            this.y = b * l;
        }
        return this;
	}

	inline public function mult(f:FastFloat):Vec2 {
		x *= f; y *= f;
		return this;
	}

	inline public function dot(v:Vec2):FastFloat {
		return x * v.x + y * v.y;
	}
	
	inline public function setFrom(v:Vec2):Vec2 {
		x = v.x; y = v.y;
		return this;
	}

	inline public function clone():Vec2 {
		return new Vec2(x, y);
	}
	
	public static function lerp(from:Vec2, to:Vec2, s:FastFloat):Vec2 {
		var target = new Vec2();
		target.x = from.x + (to.x - from.x) * s;
		target.y = from.y + (to.y - from.y) * s;
		return target;
	}

	inline public function equals(v:Vec2):Bool {
		return x == v.x && y == v.y;
	}

	inline public function length():FastFloat {
		return Math.sqrt(x * x + y * y);
	}

	inline public function normalizeTo(newLength:FastFloat):Vec2 {
		var v = normalize();
		v = mult(newLength);
		return v;
	}

	inline public function sub(v:Vec2):Vec2 {
		x -= v.x; y -= v.y;
		return this;
	}

	public static inline function distance(v1:Vec2, v2:Vec2):FastFloat {
		return distancef(v1.x, v1.y, v2.x, v2.y);
	}

	public static inline function distancef(v1x:FastFloat, v1y:FastFloat, v2x:FastFloat, v2y:FastFloat):FastFloat {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		return Math.sqrt(vx * vx + vy * vy);
	}

	inline public function distanceTo(p:Vec2):FastFloat {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y));
	}

	inline public function clamp(fmin:FastFloat, fmax:FastFloat):Vec2 {
		var n = length();
		var v = this;

		if (n < fmin) {
			v = normalizeTo(fmin);
		}
		else if (n > fmax) {
			v = normalizeTo(fmax);
		}
		return v;
	}

	inline public function map(value:Vec2, leftMin:Vec2, leftMax:Vec2, rightMin:Vec2, rightMax:Vec2):Vec2 {
		x = Math.map(value.x, leftMin.x, leftMax.x, rightMin.x, rightMax.x);
		y = Math.map(value.y, leftMin.y, leftMax.y, rightMin.y, rightMax.y);
		return this;
	}

	public static function xAxis():Vec2 { return new Vec2(1.0, 0.0); }
	public static function yAxis():Vec2 { return new Vec2(0.0, 1.0); }
	public static function one():Vec2 { return new Vec2(1.0, 1.0); }
	public static function zero():Vec2 { return new Vec2(0.0, 0.0); }
	public static function back():Vec2 { return new Vec2(0.0, -1.0); }
	public static function forward():Vec2 { return new Vec2(0.0, 1.0); }
	public static function left():Vec2 { return new Vec2(-1.0, 0.0); }
	public static function right():Vec2 { return new Vec2(1.0, 0.0); }
	public static function negativeInfinity():Vec2 { return new Vec2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY); }
	public static function positiveInfinity():Vec2 { return new Vec2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY); }

	public function toString():String {
		return "(" + this.x + ", " + this.y + ")";
	}
}
