## Going the Distance

This contains scripts that do various distance calculations.

## Word Distance

Calculate "distance" between two words where distance is the "cost" it would take to change word B into word A

## Dirty

If characters do not match, change them.

Run:

```
$ ruby lib/dirty_distance.rb far foo
# => 2
```


This is very quick and requires 0(n) comparisons (only iterates over first string, however it does not take into account every way possible to modify a word. In addition to changing letters, we can also delete and insert letters.

For example the with this algorithm against `saturday and `sunday` you would expect a small number, they both start with `s` and have similar substrings `day` but:

```
$ ruby lib/dirty_distance.rb saturday sunday
# => 7
```

Ouch. For a more accurate algorithm you can use Levenshtein


### Algorithm:


```
def distance(str1, str2)
  cost = 0
  str1.each_char.with_index do |char, index|
    cost += 1 if str2[index] != char
  end
  cost
end
```

## Levenshtein

Our 3 operations we check for are insertion (adding an extra character), deletion (removing a character), and substitution (changing one character for another). The difficulty of calculating deletion and insertion is that the length of our strings change. Even so this is the basic logic.

We can use this logic, iterate over each set of characters and look for the following scenarios.

- Match:

Two characters match each other, distance is zero

```
distance("s", "s")
# => 0
```

Move on, nothing to see here

- Deletion:

If the the removing the current character in the provided string matches the next character, this means that we should delete the character.

```
distance("schneems", "zschneems")
# => 1
```

Another way to look at this is we compare the substring of `"zschneems"[1..-1]` and see if it matches the first string. If it does bingo.

- Insertion

If the removing a charcter from the target string matches the next character (or the whole substring), this means we should add a character

```
distance("schneems", "chneems")
```

Here `"schneems"[1..-1]` matches `"chneems"` so we should insert a character.

- Substitution

If a character does not qualify for deletion, addition, and is not a match, by definition we must substitute a character. Another way to look at this is

```
distance("zchneems", "schneems")
```

If the first characters do not match `"z" != "s"` but the substring does

```
"zchneems"[1..-1] == "schneems"[1..-1]
# => true
```

Then you've got a substitution on your hands.

To change "sunday" into "saturday" you can do it with insertion

We we INSERT the "at" after the "s"

```
"sunday" => "satunday"
```

Now we SUBSTITUTE the "n" for an "r"

```
"satunday" => "saturday"
```

Boom, only 3 changes gets us the desired result. The distance between the two words is now 3. Previously the "dirty" method calculated it was 7 which was pretty far off.

## Levenshtein - Recursive

With these rules in mind we can get a more accurate result. But how to calculate this? We can compare each sub string for every possible permutation. To do this we can use a recursive algorithm.

The recursive algorithm is simple but dirty. For comparing `sunday` to `saturday` it takes 1647 comparison. The value is that it is accurate, while the "dirty" implementation only took 7 iterations, it also produced an incorrect result.


```
$ ruby lib/levenshtein_recusive.rb saturday sunday
# => 3
```

### Algorithm


```
def distance(str1, str2)
  return str2.length if str1.empty?
  return str1.length if str2.empty?

  return distance(str1[1..-1], str2[1..-1]) if str1[0] == str2[0] # match
  l1 = distance(str1, str2[1..-1])          # deletion
  l2 = distance(str1[1..-1], str2)          # insertion
  l3 = distance(str1[1..-1], str2[1..-1])   # substitution
  return 1 + [l1,l2,l3].min                 # increment cost
end
```

If either of the strings is empty, then the distance between the two is the length of the other.

```
  return str2.length if str1.empty?
  return str1.length if str2.empty?
```

If the first character matches, we only need to know the distance of the substrings

```
  return distance(str1[1..-1], str2[1..-1]) if str1[0] == str2[0] # match
```

If we get past this point, we know we haven't matched, now we can look to see what the distance would be if we deleted one character

```
  l1 = distance(str1, str2[1..-1])          # deletion
```

Distance if we add a character

```
  l2 = distance(str1[1..-1], str2)          # insertion
```

And the distance of substituting a character

```
  l3 = distance(str1[1..-1], str2[1..-1])   # substitution
```

Finally we figure out which of these methods was the cheapest, and add one to it (to account for this iteration), we return that value.

It's a bit confusing to totally wrap your head around, but go back to the deletion/insertion/substitution examples above and it helps.

## Levenshtein - Matrix

So the dirty version is fast but not accurate, and the recursive version is accurate but not fast. If we look closely at the recursive algorithm, it looks like we're comparing different versions of substrings. We're also using these substring calculations in our own calculations. Unfortunately we're re-calculating over and over again. This comparison could easily be cached

```
Comparing 'day' 'ay'
```

Since we're dealing with two lengths of string we can cache distance calculations in a matrix form.

The result will be O(n*m) calculations where n and m are the lengths of the two strings.

```
$ levenshtein_matrix saturday sunday
# => 3
```


### Algorithm:

```
def levenshtein_distance(str1, str2)
  n = str1.length
  m = str2.length

  d = (0..m).to_a

  str1.each_char.each_with_index do |char1,i|
    e = i+1
    str2.each_char.each_with_index do |char2, j|

      cost = (char1 == char2) ? 0 : 1
      x = [
           d[j+1] + 1, # insertion
           e + 1,      # deletion
           d[j] + cost # substitution
          ].min
      d[j] = e
      e = x
    end

    d[m] = x
  end

  return x
end
```

```
doh


               AAA                                           tttt           !!!
              A:::A                                       ttt:::t          !!:!!
             A:::::A                                      t:::::t          !:::!
            A:::::::A                                     t:::::t          !:::!
           A:::::::::A          rrrrr   rrrrrrrrr   ttttttt:::::ttttttt    !:::!
          A:::::A:::::A         r::::rrr:::::::::r  t:::::::::::::::::t    !:::!
         A:::::A A:::::A        r:::::::::::::::::r t:::::::::::::::::t    !:::!
        A:::::A   A:::::A       rr::::::rrrrr::::::rtttttt:::::::tttttt    !:::!
       A:::::A     A:::::A       r:::::r     r:::::r      t:::::t          !:::!
      A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr      t:::::t          !:::!
     A:::::::::::::::::::::A     r:::::r                  t:::::t          !!:!!
    A:::::AAAAAAAAAAAAA:::::A    r:::::r                  t:::::t    tttttt !!!
   A:::::A             A:::::A   r:::::r                  t::::::tttt:::::t
  A:::::A               A:::::A  r:::::r                  tt::::::::::::::t !!!
 A:::::A                 A:::::A r:::::r                    tt:::::::::::tt!!:!!
AAAAAAA                   AAAAAAArrrrrrr                      ttttttttttt   !!!
```


```
colossal
       d8888         888    888
      d88888         888    888
     d88P888         888    888
    d88P 888 888d888 888888 888
   d88P  888 888P"   888    888
  d88P   888 888     888    Y8P
 d8888888888 888     Y88b.   "
d88P     888 888      "Y888 888
```

```
roman
      .o.                    .   .o.
     .888.                 .o8   888
    .8"888.     oooo d8b .o888oo 888
   .8' `888.    `888""8P   888   Y8P
  .88ooo8888.    888       888   `8'
 .8'     `888.   888       888 . .o.
o88o     o8888o d888b      "888" Y8P
```


```
alligator2
    :::     ::::::::: ::::::::::: :::
  :+: :+:   :+:    :+:    :+:     :+:
 +:+   +:+  +:+    +:+    +:+     +:+
+#++:++#++: +#++:++#:     +#+     +#+
+#+     +#+ +#+    +#+    +#+     +#+
#+#     #+# #+#    #+#    #+#
###     ### ###    ###    ###     ###
```



```
broadway

         .8.          8 888888888o. 8888888 8888888888
        .888.         8 8888    `88.      8 8888
       :88888.        8 8888     `88      8 8888
      . `88888.       8 8888     ,88      8 8888
     .8. `88888.      8 8888.   ,88'      8 8888
    .8`8. `88888.     8 888888888P'       8 8888
   .8' `8. `88888.    8 8888`8b           8 8888
  .8'   `8. `88888.   8 8888 `8b.         8 8888
 .888888888. `88888.  8 8888   `8b.       8 8888
.8'       `8. `88888. 8 8888     `88.     8 8888
```