defmodule Poker do
  def deal(list) do
    [first,second,third,fourth | pool] = list
    c1 = [first,third]
    c2 = [second,fourth]
    hand1 = c1 ++ pool
    hand2 = c2 ++ pool
    hand1 = Enum.map(hand1, fn(n) -> rankCard(n) end)
    hand2 = Enum.map(hand2, fn(n) -> rankCard(n) end)
    [w, x | _pool] = hand1
    [y, z | _pool] = hand2
    p1 = [w,x]
    p2 = [y,z]
    hand1 = Enum.sort(hand1)
    hand2 = Enum.sort(hand2)
    winner = order(hand1, hand2, p1, p2)
    convertOutput(winner)
  end

  defp num(hand) do Enum.map(hand, fn({numbers, _suit}) -> numbers end) end
  defp suits(hand) do Enum.map(hand, fn({_numbers, suit}) -> suit end) end
  defp slice(hand, index, diff, length) do hand |> Enum.slice((index-diff),length) end

  defp helper(hand, var, index, diff, length) do
    if var != 0 do
      slice(hand,index,diff,length)
    else
      false
    end
  end

  defp rankCard(card) do
    suit = if(rem(card,13) == 0, do: div(card,13)-1, else: div(card,13))
    card = case (rem(card, 13)) do
      0 -> 13
      1 -> 14
      _ ->rem(card, 13)
    end
    case suit do
      0 -> {card, "C"}
      1 -> {card, "D"}
      2 -> {card, "H"}
      3 -> {card, "S"}
    end
  end

  defp order(hand1, hand2, p1, p2) do
    tie(      royalFlush(hand2),    royalFlush(hand1),    p1, p2) ||
    tie(      straightFlush(hand1), straightFlush(hand2), p1, p2) ||
    tie(      quads(hand1),         quads(hand2),         p1, p2) ||
    tieFull(  fullHouse(hand1),     fullHouse(hand2),     p1, p2) ||
    tie(      flush(hand1),         flush(hand2),         p1, p2) ||
    tie(      straight(hand1),      straight(hand2),      p1, p2) ||
    tie(      trips(hand1),         trips(hand2),         p1, p2) ||
    tie(      twoPair(hand1),       twoPair(hand2),       p1, p2) ||
    tie(      pair(hand1),          pair(hand2),          p1, p2) ||
    tie(      highCard(hand1),       highCard(hand2),     p1, p2)
  end

  defp tie(hand1, hand2, p1, p2) do
    cond do
      hand1 && !hand2 -> hand1
      hand2 && !hand1 -> hand2
      hand1 && hand2 -> compareRanks(hand1, hand2, p1, p2)
      true -> false
    end
  end

  defp compareRanks(hand1, hand2, p1, p2) do
    rank1 = Enum.map(hand1, fn {rank, _suit} -> rank end)
    rank2 = Enum.map(hand2, fn {rank, _suit} -> rank end)
    p1new = Enum.map(p1, fn {rank, _suit} -> rank end)
    p2new = Enum.map(p2, fn {rank, _suit} -> rank end)
    lastRank1 = List.last(rank1)
    lastRank2 = List.last(rank2)
    sumRank1 = Enum.sum(rank1)
    sumRank2 = Enum.sum(rank2)
    sumP1 = Enum.sum(p1new)
    sumP2 = Enum.sum(p2new)
    cond do
      lastRank1 > lastRank2 -> hand1
      lastRank1 < lastRank2 -> hand2
      lastRank1 == lastRank2 ->
        cond do
          sumRank1 > sumRank2 -> hand1
          sumRank2 > sumRank1 -> hand2
          sumRank1 == sumRank2 ->
            cond do
              sumP1 > sumP2 -> hand1
              true -> hand2
            end
          true -> nil
        end
      true -> nil
    end
  end

  defp tieFull(hand1, hand2, p1, p2) do
    cond do
      hand1 && !hand2 -> hand1
      hand2 && !hand1 -> hand2
      hand1 && hand2 -> fullHelp(hand1, hand2, p1, p2)
      true -> false
    end
  end

  defp fullHelp(hand1, hand2, p1, p2) do
    rank1 = Enum.map(hand1, fn {rank, _suit} -> rank end)
    rank2 = Enum.map(hand2, fn {rank, _suit} -> rank end)
    {trip1,duo1} = case rank1 do
      [y,y,x,x,x] -> {x,y}
      [x,x,x,y,y] -> {x,y}
    end
    {trip2,duo2} = case rank2 do
      [y,y,x,x,x] -> {x,y}
      [x,x,x,y,y] -> {x,y}
    end
    cond do
      trip1 > trip2 -> hand1
      trip2 > trip1 -> hand2
      trip1 == trip2 ->
        cond do
          duo1 > duo2 -> hand1
          duo2 > duo1 -> hand2
          true -> compareRanks(hand1, hand2, p1, p2)
        end
      true -> false
    end
  end

  defp convertOutput(hand) do
    hand = Enum.map(hand, fn({number, suit}) -> if number==14, do: {1, suit}, else: {number, suit} end)
    Enum.map(hand, fn({number, suit}) -> "#{number}" <> suit end)
  end

  defp royalFlush(hand) do
    numbers = num(hand)
    suit = suits(hand)
    sequence = case numbers do
      [_,_,10,11,12,13,14] -> 1
      [_,10,11,12,13,14,_] -> 2
      [10,11,12,13,14,_,_] -> 3
      _ -> 0
    end
    symbol = case suit do
      [_,_,x,x,x,x,x] -> 1
      [_,x,x,x,x,x,_] -> 2
      [x,x,x,x,x,_,_] -> 3
      _ -> 0
    end
    cond do
      sequence == symbol && sequence != 0 -> slice(hand,3,sequence,5)
      true -> false
    end
  end

  defp straightFlush(hand) do
    hand = Enum.map(hand, fn({number, suit}) -> {suit, number} end)
    hand = Enum.sort(hand)
    hand = Enum.map(hand, fn({suit, number}) -> {number, suit} end)
    sequence = straightCheck(hand)
    cond do
      sequence != 0 && flushCheck(sequence) != 0 -> sequence
      true -> false
    end
  end

  defp quads(hand) do
    numbers = num(hand)
    number = case numbers do
      [_,_,_,x,x,x,x] -> 1
      [_,_,x,x,x,x,_] -> 2
      [_,x,x,x,x,_,_] -> 3
      [x,x,x,x,_,_,_] -> 4
      _ -> 0
    end
    helper(hand,number,4,number,4)
  end

  defp fullHouse(hand) do
    numbers = num(hand)
    number = case numbers do
      [_,_,y,y,x,x,x] -> 1
      [_,y,y,_,x,x,x] -> 2
      [y,y,_,_,x,x,x] -> 3
      [_,y,y,x,x,x,_] -> 4
      [y,y,_,x,x,x,_] -> 5
      [_,_,x,x,x,y,y] -> 6
      [y,y,x,x,x,_,_] -> 7
      [_,x,x,x,_,y,y] -> 8
      [_,x,x,x,y,y,_] -> 9
      [x,x,x,_,_,y,y] -> 10
      [x,x,x,_,y,y,_] -> 11
      [x,x,x,y,y,_,_] -> 12
      _ -> 0
    end
    cond do
      number == 1 ->  hand |> Enum.slice(2,5)
      number == 2 ->  Enum.slice(hand,1,2) ++ Enum.slice(hand,4,3)
      number == 3 ->  Enum.slice(hand,0,2) ++ Enum.slice(hand,4,3)
      number == 4 ->  hand |> Enum.slice(1,5)
      number == 5 ->  Enum.slice(hand,0,2) ++ Enum.slice(hand,3,3)
      number == 6 ->  hand |> Enum.slice(2,5)
      number == 7 ->  hand |> Enum.slice(0,5)
      number == 8 ->  Enum.slice(hand,1,3) ++ Enum.slice(hand,5,2)
      number == 9 ->  hand |> Enum.slice(1,5)
      number == 10 -> Enum.slice(hand,0,3) ++ Enum.slice(hand,5,2)
      number == 11 -> Enum.slice(hand,0,3) ++ Enum.slice(hand,4,2)
      number == 12 -> hand |> Enum.slice(0,5)
      true -> false
    end
  end

  defp flush(hand) do
    hand = Enum.map(hand, fn({number, suit}) -> {suit, number} end)
    hand = Enum.sort(hand)
    hand = Enum.map(hand, fn({suit,number}) -> {number, suit} end)
    cond do
      flushCheck(Enum.slice(hand,2,5)) != 0 -> hand |> Enum.slice(2,5)
      flushCheck(Enum.slice(hand,1,5)) != 0 -> hand |> Enum.slice(1,5)
      flushCheck(Enum.slice(hand,0,5)) != 0 -> hand |> Enum.slice(0,5)
      true -> false
    end
  end

  defp straight(hand) do
    new = straightCheck(hand)
    cond do
      new == 0 -> false
      true -> new
    end
  end

  defp trips(hand) do
    numbers = num(hand)
    number = case numbers do
      [_,_,_,_,x,x,x] -> 1
      [_,_,_,x,x,x,_] -> 2
      [_,_,x,x,x,_,_] -> 3
      [_,x,x,x,_,_,_] -> 4
      [x,x,x,_,_,_,_] -> 5
      _ -> 0
    end
    helper(hand,number,5,number,3)
  end

  defp twoPair(hand) do
    numbers = num(hand)
    number = case numbers do
      [_,_,_,y,y,x,x] -> 1
      [_,_,y,y,_,x,x] -> 2
      [_,y,y,_,_,x,x] -> 3
      [y,y,_,_,_,x,x] -> 4
      [_,_,y,y,x,x,_] -> 5
      [_,y,y,_,x,x,_] -> 6
      [y,y,_,_,x,x,_] -> 7
      [_,y,y,x,x,_,_] -> 8
      [y,y,_,x,x,_,_] -> 9
      [y,y,x,x,_,_,_] -> 10
      _ -> 0
    end
    cond do
      number == 1 ->  hand |> Enum.slice(3,4)
      number == 2 ->  Enum.slice(hand,2,2) ++ Enum.slice(hand,5,2)
      number == 3 ->  Enum.slice(hand,1,2) ++ Enum.slice(hand,5,2)
      number == 4 ->  Enum.slice(hand,0,2) ++ Enum.slice(hand,5,2)
      number == 5 ->  hand |> Enum.slice(2,4)
      number == 6 ->  Enum.slice(hand,1,2) ++ Enum.slice(hand,4,2)
      number == 7 ->  Enum.slice(hand,0,2) ++ Enum.slice(hand,4,2)
      number == 8 ->  hand |> Enum.slice(1,4)
      number == 9 ->  Enum.slice(hand,0,2) ++ Enum.slice(hand,3,2)
      number == 10 -> hand |> Enum.slice(0,4)
      true -> false
    end
  end

  defp pair(hand) do
    numbers = num(hand)
    number = case numbers do
      [_,_,_,_,_,x,x] -> 1
      [_,_,_,_,x,x,_] -> 2
      [_,_,_,x,x,_,_] -> 3
      [_,_,x,x,_,_,_] -> 4
      [_,x,x,_,_,_,_] -> 5
      [x,x,_,_,_,_,_] -> 6
      _ -> 0
    end
    helper(hand,number,6,number,2)
  end

  defp highCard(hand) do
    hand |> Enum.slice(6,1)
  end

  defp flushCheck(hand) do
    suits = suits(hand)
    case suits do
      [x,x,x,x,x] -> 1
      _ -> 0
    end
  end

  defp straightCheck(hand) do
    nums = Enum.dedup_by(hand, fn({number, _suit}) -> number end)
    length = Enum.count(nums)
    case length do
      7 ->
        (numbers = num(nums)
        x = Enum.at(numbers,2)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,2,5) -> nums |> Enum.slice(2,5)
          [x-1,x,x+1,x+2,x+3] == Enum.slice(numbers,1,5) -> nums |> Enum.slice(1,5)
          [x-2,x-1,x,x+1,x+2] == Enum.slice(numbers,0,5) -> nums |> Enum.slice(0,5)
          true -> aceLow(nums)
        end)
      6 ->
        (numbers = num(nums)
        x = Enum.at(numbers,1)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,1,5) -> nums |> Enum.slice(1,5)
          [x-1,x,x+1,x+2,x+3] == Enum.slice(numbers,0,5) -> nums |> Enum.slice(0,5)
          true -> aceLow(nums)
        end)
      5 ->
        (numbers = num(nums)
        x = Enum.at(numbers,0)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,0,5) -> nums |> Enum.slice(0,5)
          true -> aceLow(nums)
        end)
      _ -> 0
    end

  end

  defp aceLow(hand) do
    hand = Enum.map(hand, fn({number, suit}) -> if number==14, do: {1, suit}, else: {number, suit} end)
    hand = Enum.sort(hand)
    numbers = num(hand)
    length = Enum.count(hand)
    case length do
      7 ->
        (x = Enum.at(numbers,2)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,2,5) -> hand |> Enum.slice(2,5)
          [x-1,x,x+1,x+2,x+3] == Enum.slice(numbers,1,5) -> hand |> Enum.slice(1,5)
          [x-2,x-1,x,x+1,x+2] == Enum.slice(numbers,0,5) -> hand |> Enum.slice(0,5)
          true -> 0
        end)
      6 ->
        (x = Enum.at(numbers,1)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,1,5) -> hand |> Enum.slice(1,5)
          [x-1,x,x+1,x+2,x+3] == Enum.slice(numbers,0,5) -> hand |> Enum.slice(0,5)
          true -> 0
        end)
      5 ->
        (x = Enum.at(numbers,0)
        cond do
          [x,x+1,x+2,x+3,x+4] == Enum.slice(numbers,0,5) -> hand |> Enum.slice(0,5)
          true -> 0
        end)
      _ -> 0
    end
  end

end
