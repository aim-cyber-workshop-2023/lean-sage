import Mathlib.Tactic.Polyrith
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.Tactic.RewriteSearch

open Lean Mathlib Json


def sageOutput (args : Array String) : IO String :=
  IO.Process.run { cmd := "sage", args := args }

def String.parseNatList (l : String) : List ℕ :=
  (((l.drop 1).dropRight 2).split (. = ' ')).map
    (fun s => s.stripSuffix ",") |> .map String.toNat!

unsafe def sageFactorUnsafe (n : ℕ) : List ℕ :=
  let args := #["-c", s!"print(prime_factors({n}))"] ;
  match unsafeBaseIO (sageOutput args).toBaseIO with
  | .ok l => l.parseNatList
  | .error _ => []

@[implemented_by sageFactorUnsafe]
opaque sageFactorization (n : ℕ) : List ℕ

axiom sageFactorizationCorrect (n : ℕ) :
  ∀ p : ℕ, p ∈ sageFactorization n ↔ p ∣ n ∧ p.Prime

#eval sageFactorization 102343422332


def computeIsPrimitiveRoot (a p : ℕ) : Bool :=
  (sageFactorization (p - 1)).all
    (fun q => ¬ a^((p - 1)/q) ≡ 1 [ZMOD p])

theorem computeIsPrimitiveRoot_correct (a p : ℕ) :
  computeIsPrimitiveRoot a p = true ↔
    IsPrimitiveRoot a p :=
sorry
