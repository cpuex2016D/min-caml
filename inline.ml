open KNormal

(* ����饤��Ÿ������ؿ��κ��祵���� (caml2html: inline_threshold) *)
let threshold = ref 0 (* Main��-inline���ץ����ˤ�ꥻ�åȤ���� *)

let rec size = function
  | IfEq(_, _, e1, e2) | IfLE(_, _, e1, e2)
    | Let(_, e1, e2) | LetRec({ body = e1 }, e2)|Let_Ref(_,e1,e2) -> 1 + size e1 + size e2
  | LetTuple(_, _, e)|ForLE(_,e) -> 1 + size e
  | _ -> 1
let rec loop_exit = function
    | IfEq(_, _, e1, e2) | IfLE(_, _, e1, e2)
      | Let(_, e1, e2) | LetRec({ body = e1 }, e2)|Let_Ref(_,e1,e2) ->
       (loop_exit e1)||(loop_exit e2)
    |LetTuple(_,_,e)->loop_exit e
    |ForLE _ ->true
    |_ ->false

           

let rec g env = function (* ����饤��Ÿ���롼�������� (caml2html: inline_g) *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g env e1, g env e2)
  | Let(xt, e1, e2) -> Let(xt, g env e1, g env e2)
  | Let_Ref(xt,e1,e2) ->Let_Ref(xt,g env e1,g env e2)
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) -> (* �ؿ�����ξ�� (caml2html: inline_letrec) *)
     let env = if (S.mem x (fv e1))(*||(loop_exit e1)(*�Ƶ��ؿ���Ƚ��*)*)
               then env
               else if (size e1) > !threshold
               then env
               else M.add x (yts, e1) env in
      LetRec({ name = (x, t); args = yts; body = g env e1}, g env e2)
  | App(x, ys) when M.mem x env -> (* �ؿ�Ŭ�Ѥξ�� (caml2html: inline_app) *)
      let (zs, e) = M.find x env in
      (*Format.eprintf "inlining %s@." x;*)
      let env' =
	List.fold_left2
	  (fun env' (z, t) y -> M.add z y env')
	  M.empty
	  zs
	  ys in
      Alpha.g env' e
  | LetTuple(xts, y, e) -> LetTuple(xts, y, g env e)
  |ForLE(cs,e) ->ForLE(cs,g env e)
  |LetPara({pargs=xts;
            index =cs
            ;accum=acc
            ;pbody=e1},e2) ->
    LetPara({pargs=xts;
             index =cs
            ;accum=acc
            ;pbody=g env e1},g env e2) 
                   
  | e -> e

let f e =(* Printf.printf "\n";*) g M.empty e
