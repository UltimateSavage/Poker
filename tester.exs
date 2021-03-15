tests = 100
players = 2

cardsIntToStr = fn (cardInts) -> for i <- cardInts, do: "#{rem((i - 1), 13) + 1}#{{"C", "D", "H", "S"} |> elem(floor((i - 1) / 13))}" end
getSol = fn (perm) ->
    cards = for card <- cardsIntToStr.(perm), do: (
        case Integer.parse(card) |> elem(0) do
            1  -> "A" <> String.last(card)
            13 -> "K" <> String.last(card)
            12 -> "Q" <> String.last(card)
            11 -> "J" <> String.last(card)
            _  -> card
        end
    )

    url = 'https://api.pokerapi.dev/v1/winner/texas_holdem?cc=#{Enum.take(cards, -5) |> Enum.join(",")}#{
        for player <- 1..players, do: ("&pc%5B%5D=#{Enum.at(cards, player - 1) <> "," <> Enum.at(cards, player + players - 1)}")}'

    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)
    response = "#{(:httpc.request(url)) |> elem(1) |> elem(2)}" |> String.split("\"")

    ranking = Enum.at(response, 13)
    sol = for card <- (Enum.at(response, 9) |> String.split(",")), do: (
        cond do
            String.contains?(card, "A") -> "1" <> String.last(card)
            String.contains?(card, "K") -> "13" <> String.last(card)
            String.contains?(card, "Q") -> "12" <> String.last(card)
            String.contains?(card, "J") -> "11" <> String.last(card)
            true                        -> card
        end
    )

    ranks = for card <- sol, do: (Integer.parse(card) |> elem(0))

    cond do
        ranking == "high_card"      -> [Enum.at(sol, -1)]
        ranking == "pair" ||
        ranking == "two_pair"       -> Enum.filter(sol, fn(card) -> Enum.count(ranks, fn(x) -> x == (Integer.parse(card) |> elem(0)) end) == 2 end)
        ranking == "three_of_kind"  -> Enum.filter(sol, fn(card) -> Enum.count(ranks, fn(x) -> x == (Integer.parse(card) |> elem(0)) end) == 3 end)
        ranking == "four_of_kind"   -> Enum.filter(sol, fn(card) -> Enum.count(ranks, fn(x) -> x == (Integer.parse(card) |> elem(0)) end) == 4 end)
        true                        -> sol
    end
end

perms = for _n <- 1..tests, do: Stream.repeatedly(fn -> :rand.uniform(52) end) |> Stream.uniq |> Enum.take(players * 2 + 5)
sols = for perm <- perms, do: getSol.(perm)

cards = [   "1C", "2C", "3C", "4C", "5C", "6C", "7C", "8C", "9C", "10C", "11C", "12C", "13C",
            "1D", "2D", "3D", "4D", "5D", "6D", "7D", "8D", "9D", "10D", "11D", "12D", "13D",
            "1H", "2H", "3H", "4H", "5H", "6H", "7H", "8H", "9H", "10H", "11H", "12H", "13H",
            "1S", "2S", "3S", "4S", "5S", "6S", "7S", "8S", "9S", "10S", "11S", "12S", "13S" ]

allScores = for test <- 0..(length(perms)-1) do

        input = Enum.at(perms, test)
        deal = for id <- input do Enum.at(cards, id-1) end

        try do
                youSaid = Poker.deal(input)
                shouldBe = Enum.sort(Enum.at(sols, test))
                common = Enum.sort(youSaid -- (youSaid -- shouldBe))

        cond do
            length(youSaid) > 5 ->
                IO.puts "Test #{test+1} DISCREPANCY: " <> inspect(input)
                IO.puts "  P1:   " <> inspect([Enum.at(deal, 0), Enum.at(deal, 2)])
                IO.puts "  P2:   " <> inspect([Enum.at(deal, 1), Enum.at(deal, 3)])
                IO.puts "  Pool: " <> inspect(Enum.drop(deal, 4))
                IO.puts "  You returned:   " <> inspect(youSaid)
                IO.puts "  Returned more than five cards! Test FAILED!"
                0
            common == shouldBe ->
                # c = length(common)
                # IO.puts "Test #{test+1} FULL MARKS  (#{c} of #{c} cards correct)"
                1
                        true ->
                IO.puts "Test #{test+1} DISCREPANCY: " <> inspect(input)
                IO.puts "  P1:   " <> inspect([Enum.at(deal, 0), Enum.at(deal, 2)])
                IO.puts "  P2:   " <> inspect([Enum.at(deal, 1), Enum.at(deal, 3)])
                IO.puts "  Pool: " <> inspect(Enum.drop(deal, 4))
                IO.puts "  You returned:   " <> inspect(youSaid)
                IO.puts "  Should contain: " <> inspect(shouldBe)
                IO.puts "  #{length common} of #{length shouldBe} cards correct"
                length(common) / length(shouldBe)
        end
        rescue
                _ ->
                        IO.puts "Test #{test+1} ERROR - Runtime error on input " <> inspect(input); 0
        end
end

allScores = List.flatten(allScores)
scorePct = 100*Enum.sum(allScores) / length(allScores)
IO.puts "\nTotal score: #{scorePct}%  (#{Enum.sum allScores}/#{length allScores} points)"
