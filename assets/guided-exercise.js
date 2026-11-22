/* guided-exercise.js: the guided mode of an exercise (decision 0026). Master copy in
   _design/assets/; guided-exercise.lua builds the HTML and inlines this script on pages that use
   the block. It only opens steps, checks answers and gives feedback; nothing is stored.

   A slot (span.casilla) carries its reference: data-valor (a decimal), data-exacto (1: the
   answer must equal it; 0: it is rounded), data-dec (its decimals), data-min (the decimals the
   student must type). An answer is a number with a decimal point or comma, or a fraction a/b.
   A rounded reference accepts an answer within half a unit of the last decimal of either. */
(function () {
  "use strict";
  var EN = (document.documentElement.lang || "").slice(0, 2) === "en";
  var T = EN ? {
    right: "Correct.",
    wrong: "Not correct.",
    again: "Not correct. Try once more.",
    shown: "Here is the answer; go on to the next step.",
    offer: "Not correct. Want to go step by step?",
    empty: "Write your answer first.",
    number: "Write a number, such as 2.5 or 1/2.",
    decimals: function (n) { return "Write at least " + n + (n === 1 ? " decimal." : " decimals."); },
    done: "Steps done. Now give the final answer above, or compare with the solution.",
    doneNoFinal: "Steps done. Compare with the solution."
  } : {
    right: "Correcto.",
    wrong: "No es correcto.",
    again: "No es correcto. Inténtalo otra vez.",
    shown: "Esta es la respuesta; sigue con el próximo paso.",
    offer: "No es correcto. ¿Lo hacemos paso a paso?",
    empty: "Escribe tu respuesta primero.",
    number: "Escribe un número, por ejemplo 2,5 o 1/2.",
    decimals: function (n) { return "Escribe al menos " + n + (n === 1 ? " decimal." : " decimales."); },
    done: "Completaste los pasos. Ahora responde arriba, o compara con la solución.",
    doneNoFinal: "Completaste los pasos. Compara con la solución."
  };

  function parse(text) {
    var t = text.replace(/−/g, "-").replace(/[\s°]+/g, "");
    var m = t.match(/^([+-]?)(\d+)\/(\d+)$/);
    if (m) {
      if (+m[3] === 0) return null;
      return { value: (m[1] === "-" ? -1 : 1) * (+m[2]) / (+m[3]), decimals: Infinity,
               fraction: true };
    }
    m = t.match(/^([+-]?)(\d*)(?:[.,](\d*))?$/);
    if (!m || (m[2] === "" && !m[3])) return null;
    var dec = m[3] ? m[3].length : 0;
    return { value: parseFloat(m[1] + (m[2] || "0") + "." + (m[3] || "0")), decimals: dec,
             fraction: false };
  }

  /* "ok", "wrong", "empty", "number" or "decimals" */
  function judge(slot, text) {
    if (!text.trim()) return "empty";
    var a = parse(text);
    if (!a) return "number";
    var ref = parseFloat(slot.dataset.valor);
    var exact = slot.dataset.exacto === "1";
    var refUnit = 0.5 * Math.pow(10, -(+slot.dataset.dec || 0));
    if (!a.fraction && a.decimals < (+slot.dataset.min || 0)) return "decimals";
    var tol;
    if (exact) tol = 1e-9;
    else if (a.fraction) tol = refUnit;
    else tol = Math.max(0.5 * Math.pow(10, -a.decimals), refUnit);
    return Math.abs(a.value - ref) <= tol * (1 + 1e-9) + 1e-12 ? "ok" : "wrong";
  }

  function say(zone, text, kind) {
    var p = zone.querySelector(":scope > .guiado-retro");
    p.textContent = text;
    p.className = "guiado-retro" + (kind ? " " + kind : "");
  }

  function setup(box) {
    var intro = box.querySelector(":scope > .guiado-intento");
    var list = box.querySelector(":scope > .guiado-pasos");
    var steps = list ? Array.prototype.slice.call(list.children) : [];
    var opener = box.querySelector(".guiado-abrir");

    function slotsOf(zone) {
      return Array.prototype.slice.call(zone.querySelectorAll(".casilla")).filter(function (s) {
        return s.closest(".guiado-zona") === zone;
      });
    }
    function optionsOf(zone) {
      return Array.prototype.slice.call(zone.querySelectorAll(".opcion")).filter(function (o) {
        return o.closest(".guiado-zona") === zone;
      });
    }
    function resolved(zone) {
      var slotsDone = slotsOf(zone).every(function (s) {
        return s.classList.contains("bien") || s.classList.contains("revelado");
      });
      var opts = optionsOf(zone);
      var choiceDone = !opts.length || opts.some(function (o) {
        return o.classList.contains("bien") || o.classList.contains("revelado");
      });
      return slotsDone && choiceDone;
    }
    function focusIn(zone) {
      var target = zone.querySelector("input:not(:disabled), .opcion:not(:disabled)");
      if (target) target.focus();
    }
    function openSteps() {
      if (!list) return;
      list.classList.remove("cerrado");
      if (opener) { opener.disabled = true; opener.classList.remove("sugerido"); }
      var current = steps.filter(function (s) { return !s.classList.contains("cerrado"); });
      focusIn(current[current.length - 1] || steps[0]);
    }
    function advance(zone) {
      if (zone === intro) return;
      var i = steps.indexOf(zone);
      if (i + 1 < steps.length) {
        steps[i + 1].classList.remove("cerrado");
        focusIn(steps[i + 1]);
      } else {
        var last = zone.querySelector(":scope > .guiado-retro");
        last.textContent += " " + (intro && !resolved(intro) ? T.done : T.doneNoFinal);
      }
    }
    function after(zone, wrongs) {
      var isStep = zone !== intro;
      if (resolved(zone)) {
        var anyShown = zone.querySelector(".revelado");
        say(zone, anyShown ? T.shown : T.right, anyShown ? "" : "bien");
        var button = zone.querySelector(":scope > .guiado-acciones > .guiado-comprobar");
        if (button) button.disabled = true;
        if (!isStep && opener) opener.classList.remove("sugerido");
        advance(zone);
      } else if (wrongs) {
        if (isStep) say(zone, T.again, "mal");
        else {
          say(zone, opener ? T.offer : T.wrong, "mal");
          if (opener && !opener.disabled) opener.classList.add("sugerido");
        }
      }
    }
    function check(zone) {
      var isStep = zone !== intro;
      var wrongs = 0, message = null;
      slotsOf(zone).forEach(function (s) {
        if (s.classList.contains("bien") || s.classList.contains("revelado")) return;
        var input = s.querySelector("input");
        var verdict = judge(s, input.value);
        if (verdict === "ok") {
          s.classList.remove("mal"); s.classList.add("bien"); input.disabled = true;
        } else if (verdict === "wrong") {
          wrongs += 1;
          s.classList.add("mal");
          var tries = (+s.dataset.intentos || 0) + 1;
          s.dataset.intentos = tries;
          if (isStep && tries >= 2) {
            s.classList.remove("mal"); s.classList.add("revelado"); input.disabled = true;
          }
        } else if (!message) {
          message = verdict === "decimals" ? T.decimals(+s.dataset.min)
                  : verdict === "empty" ? T.empty : T.number;
        }
      });
      if (message && !wrongs) { say(zone, message, "mal"); return; }
      after(zone, wrongs);
      if (message && !resolved(zone)) say(zone, message, "mal");
    }
    function choose(zone, option) {
      var isStep = zone !== intro;
      var opts = optionsOf(zone);
      var row = option.closest(".opcion-fila");
      if (option.dataset.ok) {
        option.classList.add("bien");
        opts.forEach(function (o) { o.disabled = true; });
        if (row.querySelector(".opcion-retro")) row.classList.add("visto");
        after(zone, 0);
        return;
      }
      option.classList.add("mal");
      option.disabled = true;
      row.classList.add("visto");
      var tries = (+zone.dataset.intentos || 0) + 1;
      zone.dataset.intentos = tries;
      if (isStep && tries >= 2) {
        opts.forEach(function (o) {
          o.disabled = true;
          if (o.dataset.ok) o.classList.add("revelado");
        });
      }
      after(zone, 1);
    }

    [intro].concat(steps).forEach(function (zone) {
      if (!zone) return;
      var button = zone.querySelector(":scope > .guiado-acciones > .guiado-comprobar");
      if (button) button.addEventListener("click", function () { check(zone); });
      slotsOf(zone).forEach(function (s) {
        s.querySelector("input").addEventListener("keydown", function (e) {
          if (e.key === "Enter") { e.preventDefault(); check(zone); }
        });
      });
      optionsOf(zone).forEach(function (o) {
        o.addEventListener("click", function () { choose(zone, o); });
      });
    });
    if (opener) opener.addEventListener("click", openSteps);
  }

  function start() {
    Array.prototype.forEach.call(document.querySelectorAll(".guiado"), setup);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
