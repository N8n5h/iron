package iron.object;

import kha.FastFloat;
import kha.arrays.Uint32Array;
import iron.math.Vec4;
import iron.math.Mat4;
import iron.math.Quat;
import iron.data.SceneFormat;

class ObjectAnimation extends Animation {

	var updateAnim: TAnimation->Transform->Void;
	public var object: Object;
	var oactions: Array<TSceneFormat>;
	var oaction: TObj;
	var s0: FastFloat = 0.0;
	var bezierFrameIndex = -1;
	var arrayIndex = 0;

	public function new(object: Object, oactions: Array<TSceneFormat>) {
		this.object = object;
		this.oactions = oactions;
		isSkinned = false;
		if (oactions[0].objects[0].type == "visibility") {
			updateAnim = updateVisibilityAnim;
		} else {
			updateAnim = updateTransformAnim;
		}
		super();
	}

	function getAction(action: String): TObj {
		for (a in oactions) if (a != null && a.objects[0].name == action) return a.objects[0];
		return null;
	}

	override public function play(action = "", onComplete: Void->Void = null, blendTime = 0.0, speed = 1.0, loop = true) {
		super.play(action, onComplete, blendTime, speed, loop);
		if (this.action == "" && oactions[0] != null) this.action = oactions[0].objects[0].name;
		oaction = getAction(this.action);
		if (oaction != null) {
			isSampled = oaction.sampled != null && oaction.sampled;
		}
	}

	override public function update(delta: FastFloat) {
		if (!object.visible || object.culled || oaction == null) return;

		#if arm_debug
		Animation.beginProfile();
		#end

		super.update(delta);
		if (paused) return;
		if (!isSkinned) updateObjectAnim();

		#if arm_debug
		Animation.endProfile();
		#end
	}

	function updateObjectAnim() {
		updateAnim(oaction.anim, object.transform);
	}

	inline function interpolateLinear(t: FastFloat, t1: FastFloat, t2: FastFloat, v1: FastFloat, v2: FastFloat): FastFloat {
		var s = (t - t1) / (t2 - t1);
		return (1.0 - s) * v1 + s * v2;
	}

	// inline function interpolateTcb(): FastFloat { return 0.0; }

	override function isTrackEnd(track: TTrack): Bool {
		return speed > 0 ?
			frameIndex >= track.frames.length - 2 :
			frameIndex <= 0;
	}

	inline function checkFrameIndexT(frameValues: Uint32Array, t: FastFloat): Bool {
		return speed > 0 ?
			frameIndex < frameValues.length - 2 && t > frameValues[frameIndex + 1] * frameTime :
			frameIndex > 1 && t > frameValues[frameIndex - 1] * frameTime;
	}

	@:access(iron.object.Transform)
	function updateTransformAnim(anim: TAnimation, transform: Transform) {
		if (anim == null) return;

		var total = anim.end * frameTime - anim.begin * frameTime;

		if (anim.has_delta) {
			var t = transform;
			if (t.dloc == null) { t.dloc = new Vec4(); t.drot = new Quat(); t.dscale = new Vec4(); }
			t.dloc.set(0, 0, 0);
			t.dscale.set(0, 0, 0);
			t._deulerX = t._deulerY = t._deulerZ = 0.0;
		}

		for (track in anim.tracks) {

			if (frameIndex == -1) rewind(track);
			var sign = speed > 0 ? 1 : -1;

			// End of current time range
			var t = time + anim.begin * frameTime;
			while (checkFrameIndexT(track.frames, t)) frameIndex += sign;

			// No data for this track at current time
			if (frameIndex >= track.frames.length) continue;

			// End of track
			if (time > total) {
				if (onComplete != null) onComplete();
				if (loop) rewind(track);
				else { frameIndex -= sign; paused = true; }
				return;
			}

			var ti = frameIndex;
			var t1 = track.frames[ti] * frameTime;
			var t2 = track.frames[ti + sign] * frameTime;
			var v1 = track.values[ti];
			var v2 = track.values[ti + sign];

			var value = interpolateLinear(t, t1, t2, v1, v2);

			switch (track.target) {
				case "xloc": transform.loc.x = value;
				case "yloc": transform.loc.y = value;
				case "zloc": transform.loc.z = value;
				case "xrot": transform.setRotation(value, transform._eulerY, transform._eulerZ);
				case "yrot": transform.setRotation(transform._eulerX, value, transform._eulerZ);
				case "zrot": transform.setRotation(transform._eulerX, transform._eulerY, value);
				case "qwrot": transform.rot.w = value;
				case "qxrot": transform.rot.x = value;
				case "qyrot": transform.rot.y = value;
				case "qzrot": transform.rot.z = value;
				case "xscl": transform.scale.x = value;
				case "yscl": transform.scale.y = value;
				case "zscl": transform.scale.z = value;
				// Delta
				case "dxloc": transform.dloc.x = value;
				case "dyloc": transform.dloc.y = value;
				case "dzloc": transform.dloc.z = value;
				case "dxrot": transform._deulerX = value;
				case "dyrot": transform._deulerY = value;
				case "dzrot": transform._deulerZ = value;
				case "dqwrot": transform.drot.w = value;
				case "dqxrot": transform.drot.x = value;
				case "dqyrot": transform.drot.y = value;
				case "dqzrot": transform.drot.z = value;
				case "dxscl": transform.dscale.x = value;
				case "dyscl": transform.dscale.y = value;
				case "dzscl": transform.dscale.z = value;
			}
		}
		object.transform.buildMatrix();
	}

	function rewindWithLast(track: TTrack, begin: Int = 0, end: Int = -1) {
		frameIndex = speed > 0 ? begin : end - 1;
		time = frameIndex * frameTime;
	}

	function spawnVisibilityCache(ti: Int, track: TTrack) {
		var layerObjects: Array<String> = track.values[ti];
		var visibleObjects = [];

		function done(obj: Object) {
			visibleObjects.push(obj);
			obj.visible = false;
		}
		for (lObj in layerObjects) Scene.active.spawnObject(lObj, this.object, done);

		lCache.frames[ti] = visibleObjects;
	}

	// takes into account the last frame as a full frame
	inline function checkFrameIndexTWithLast(start: Int, end: Int, t: FastFloat): Bool {
		return speed > 0 ?
			frameIndex < end && t > (frameIndex + 1) * frameTime :
			frameIndex > start && t > (frameIndex - 1) * frameTime;
	}

	var oldti = null;
	var oldtilayer: Map<String, Int>;
	var layerObjectsCache: Array<Object>;
	var layersCache: Map<String, VisibilityLayerCache>;
	var lCache: VisibilityLayerCache = null;
	function updateVisibilityAnim(anim: TAnimation, transform: Transform) {
		if (anim == null) return;
		if (oldtilayer == null) {
			oldtilayer = new Map<String, Int>();
			layersCache = new Map<String, VisibilityLayerCache>();
		}

		var total = (anim.end + 1) * frameTime;
		for (track in anim.tracks) {
			if (frameIndex == -1) rewindWithLast(track, anim.begin, anim.end);
			var sign = speed > 0 ? 1 : -1;
			// End of current time range
			while (checkFrameIndexTWithLast(anim.begin, anim.end, time)) frameIndex += sign;
			// No data for this track at current time
			if (frameIndex > track.frames.length) continue;

			// End of track
			if (time > total) {
				if (onComplete != null) onComplete();
				if (loop) rewindWithLast(track, anim.begin, anim.end);
				else { frameIndex -= sign; paused = true; }
				return;
			}
			var ti = frameIndex - anim.begin;
			// allow only one draw call per frame, using a cache
			if ((oldti = oldtilayer.get(track.target)) == null) { // setup cache for drawn frames
				oldti = -1;
				oldtilayer.set(track.target, oldti);
			}
			// evaluate if this is a new frame to draw
			if (oldti != ti) {
				oldti = ti;
				oldtilayer.set(track.target, oldti);
			}
			else {
				continue;
			}

			// setup and spawn the first frame
			if ((lCache = layersCache.get(track.target)) == null) {
				lCache = {
					visible: true,
					last_ti: null,
					frames: [for (i in 0...track.values.length) []]
				};
				layersCache.set(track.target, lCache);
				spawnVisibilityCache(ti, track);
			}
			// spawn the rest of the anim
			else if (track.values[ti].length != 0 && lCache.frames[ti].length == 0) {
				spawnVisibilityCache(ti, track);
			}
			// draw current frame data
			if ((layerObjectsCache = lCache.frames[ti]) != null) {
				if (layerObjectsCache.length == 0) continue;
				for (lObj in layerObjectsCache)	lObj.visible = true;
			}
			// hide old frame data
			if (lCache.last_ti != null) {
				if((layerObjectsCache = lCache.frames[lCache.last_ti]) != null) {
					for (olObj in layerObjectsCache) olObj.visible = false;
				}
			}
			lCache.last_ti = ti;
		}
	}

	override public function totalFrames(): Int {
		if (oaction == null || oaction.anim == null) return 0;
		return oaction.anim.end - oaction.anim.begin;
	}
}

#if js
typedef VisibilityLayerCache = {
#else
@:structInit class VisibilityLayerCache {
#end
	public var visible: Bool;
	public var last_ti: Null<Int>;
	public var frames: Array<Array<Object>>;
}
