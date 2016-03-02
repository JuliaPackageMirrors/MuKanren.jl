
import Base.string
using Base.Test, miniKanren.MicroKanren, FactCheck
importall miniKanren.MicroKanren


facts("Macro tests") do
  empty_state = Pair(nil(), 0)
  fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))

  context("Zzz") do
    ##println(macroexpand(:(@Zzz(x->println(x)))))
    #c = @Zzz(x -> x)
    #@fact c("Test Zzz")() --> "Test Zzz"
  end

  context("fresh") do
    fives = x -> disj(equals(x, 5), s_c -> () -> fives(x)(s_c))
    #println(macroexpand(:(miniKanren.MicroKanren.@fresh_helper(fives(x), x))))
    #println(macroexpand(:(miniKanren.MicroKanren.@fresh_helper(fives(x), x, y))))

    exp = miniKanren.MicroKanren.@fresh_helper(equals(x, 5), x)
    @fact take_all(exp(empty_state)) --> [Pair(list(Pair(Var(0), 5)), 1)]

    exp = miniKanren.MicroKanren.@fresh_helper(fives(x), x)
    @fact take(1, exp(empty_state)) --> [Pair(list(Pair(Var(0), 5)), 1)]
    #exp = miniKanren.MicroKanren.@fresh_helper(fives(x), :x)
    #println(take(1, exp(empty_state)))
#println("3331")
    #println(macroexpand(:(@fresh((:x, :y), equals(x, "111") ))))
    #println(macroexpand(:(@fresh((x, y), equals(x, "111") ))))
    ##println(take(2, call_fresh(x -> fives(x))(empty_state)))
#    #println(take(2, miniKanren.MicroKanren.@fresh_helper(:(fives(x)), :x)(empty_state)))
#    #println("222221!!!!")
    @fact take(2, call_fresh(x -> fives(x))(empty_state)) -->
      take(2, miniKanren.MicroKanren.@fresh_helper(fives(x), x)(empty_state))
    @fact take(2, (@fresh((x, y), fives(x)))(empty_state)) -->
      take(2, miniKanren.MicroKanren.@fresh_helper(fives(x), x, y)(empty_state))
    #with one arg should also work
    @fact take(2, (@fresh((x), fives(x)))(empty_state)) -->
      take(2, miniKanren.MicroKanren.@fresh_helper(fives(x), x)(empty_state))
    #println(macroexpand(:(miniKanren.MicroKanren.@fresh((x, y), equals(x, "111"), fives(y), equals(x, "22")))))
    #how to avoid stack overflow in previous expression?
    @fact take(2, (miniKanren.MicroKanren.@fresh((x, y), equals(x, "111"), equals(x, "22"), fives(y)))(empty_state)) --> []
    @fact take(2, (miniKanren.MicroKanren.@fresh((x, y), equals(x, "111"), fives(y)))(empty_state)) -->
      [Pair(list(Pair(Var(1), 5), Pair(Var(0), "111")), 2), Pair(list(Pair(Var(1), 5), Pair(Var(0),"111")), 2)]
#    ##@fact show(miniKanren.MicroKanren.fresh_helper(:(equals(x,"111")),:x)) --> show(:(call_fresh(x->equals(x,"111"))))
#    #println(@fresh((:x), equals(x, "111") ))
#    #x = @fresh () (x->equals(x, "111")) (y->equals(y, "111"))
  end
  context("conj+") do

    #println(@conj_ (x-> equals(x, "111")) ( y -> equals(y, "222")) )
    #println(macroexpand(:(call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4)))))))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), equals(b, 4))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4))))
    #println(macroexpand(:( b->@conj_(equals(a, 3), equals(b, 4)))))
    #println(take(1, exp2(empty_state)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    exp1 = call_fresh(b -> call_fresh(a -> conj(equals(a, 3), fives(b))))
    exp2 = call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), fives(b))))
    @fact take(2, exp1(empty_state)) --> take(2, exp2(empty_state))

    exp1 = call_fresh(c-> call_fresh(b -> call_fresh(a -> conj(equals(a, 3), conj(equals(b, 4), fives(c))))))
    exp2 = call_fresh(c -> call_fresh(b -> call_fresh(a -> @conj_(equals(a, 3), equals(b, 4), fives(c)))))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))

  end
  context("disj+") do
    exp1 = call_fresh(a -> disj(equals(a, 3), equals(a, 4)))
    exp2 = call_fresh(a -> @disj_(equals(a, 3), equals(a, 4)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    #test with functions defined in separate module
    exp1 = call_fresh(a -> disj(equals(a, 3), fives(a)))
    exp2 = call_fresh(a -> @disj_(equals(a, 3),  fives(a)))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))
    ##test if there is disj of more than 2 statements:
    exp1 = call_fresh(a -> disj(equals(a, 3), disj(fives(a), equals(a, 4))))
    exp2 = call_fresh(a -> @disj_(equals(a, 3),  fives(a), equals(a, 4) ))
    println(exp2(empty_state))
    @fact take(3, exp1(empty_state)) --> take(3, exp2(empty_state))
  end

  context("conde") do
    println(macroexpand(:(@conde(equals(3, 3)))))
    exp1 = @conde(equals(3, 3))
    exp2 = equals(3, 3)
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))

    exp1 = @conde(equals(3, 3), equals(4, 4))
    exp2 = disj(equals(3, 3), equals(4, 4))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))

    exp1 = @conde((equals(3, 3), equals(4, 4)))
    exp2 = conj(equals(3, 3), equals(4, 4))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))
    #println(macroexpand(:(@conde (x->println(x)) (x2->println("a")))))

    exp1 = call_fresh(a -> @conde(equals(a, 3)))
    #println(macroexpand(:(call_fresh(a -> @conde(equals(a, 3))))))
    exp2 = call_fresh(a -> @disj_(equals(a, 3)))
    @fact take_all(exp1(empty_state)) --> take_all(exp2(empty_state))

    exp1 = call_fresh(a -> @conde((equals(a, 5),  fives(a)), (equals(a, 4)) ))
    #println(macroexpand(:(call_fresh(a -> @conde((equals(a, 5),  fives(a)), (equals(a, 4)) )))))
    exp2 = call_fresh(a -> @disj_(@conj_(equals(a, 5),  fives(a)), equals(a, 4) ))
    #println(macroexpand(:(call_fresh(a -> @disj_(@conj_(equals(a, 5),  fives(a)), equals(a, 4) )))))
    @fact take(2, exp1(empty_state)) --> take(2, exp2(empty_state))

    exp1 = call_fresh(a -> call_fresh(b -> @conde((equals(a, 3),  fives(b)), (equals(a, 4)) )))
    #println(macroexpand(:(call_fresh(a -> @conde((equals(a, 5),  fives(a)), (equals(a, 4)) )))))
    exp2 = call_fresh(a -> call_fresh(b -> @disj_(@conj_(equals(a, 3),  fives(b)), equals(a, 4) )))
    #println(macroexpand(:(call_fresh(a -> @disj_(@conj_(equals(a, 5),  fives(a)), equals(a, 4) )))))
    @fact take(4, exp1(empty_state)) --> take(4, exp2(empty_state))
  end
end

facts("Run macros") do
  context("run") do
    #println(macroexpand(:(@fresh((x, y, z), equals(x, z), equals(3, y)))))
    #println(macroexpand(:(@run(1, (q), @fresh((x, y, z), equals(x, z), equals(3, y))))))
    @fact @run(1, (q), @fresh((x, y, z), equals(x, z), equals(3, y))) --> [symbol("_.0")]
    #println(result)
    @fact @run(1, (q), @fresh((x, y), equals(x, q), equals(3, y))) --> [symbol("_.0")]
    #(run 1 (y)
    #  (fresh (x z)
    #    (== x z)
    #    (== 3 y)))

    @fact @run(1, (y), @fresh((x, z), equals(x, z), equals(3, y))) --> [3]
    @fact @run(1, (q), @fresh((x, z), equals(x, z), equals(3, z), equals(q, x))) --> [3]
    #println(macroexpand(:( @run(1, (y), @fresh((x, y), equals(4, x), equals(x, y)), equals(3, y)) )))
    @fact @run(1, (y), @fresh((x, y), equals(4, x), equals(x, y)), equals(3, y)) --> [3]

    @fact @run(1, x, equals(4, 3)) --> []
    @fact @run(1, x, equals(x, 5), equals(x, 6)) --> []
  end
  context("complex run") do
    result = @run(2, q,
      @fresh((w, x, y),
        @conde(
            (
              equals(list(x, w, x), q),
              equals(y, w)
            ),
            (
              equals(list(w, x, w), q),
              equals(y, w)
              )
          )))
    @fact string(result) --> string([list(:"_.0", :"_.1", :"_.0"), list(:"_.0", :"_.1", :"_.0")])

  end
  context("infinite loop/stackoverflow") do
  #(run* (q)
#(let loop ()
#  (conde
#    ((== #f q))
#    ((== #t q))
#    ((loop)))))
  end

  context("anyo") do
    #println(macroexpand(:( @conde(g(), anyo(g)))))
    anyo = g -> @conde(g, anyo(g))

    @fact @run(10, q, anyo(@conde(
        equals(1, q),
        equals(2, q),
        equals(3, q)
        ))) --> [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
    #TODO: add example call with nevero and infinite loop

  end
end
