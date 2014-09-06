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

If we wanted to change the word `sunday` to a blank string `""` the matrix would look like this:


```
+---+---+
|   |   |
+---+---+
|   | 0 |
+---+---+
| S | 1 |
+---+---+
| U | 2 |
+---+---+
| N | 3 |
+---+---+
| D | 4 |
+---+---+
| A | 5 |
+---+---+
| Y | 6 |
+---+---+
```

It would take 6 deletions to turn `sunday` into `""`. Similarly with saturday.


```
+---+---+---+---+---+---+---+---+---+---+
|   |   | S | A | T | U | R | D | A | Y |
+---+---+---+---+---+---+---+---+---+---+
|   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
+---+---+---+---+---+---+---+---+---+---+
```

It would take 8 deletions to turn `saturday` into `""`. Now we can add one character at a time to see how the rest of the algorithm will work.


### Skip - Step

To turn `s` into `saturday` we can see we don't need to do anything for the first character since s matches s, we can skip the step:


```
+---+---+---+
|   |   | S |
+---+---+---+
|   | 0 | 1 |
+---+---+---+
| S | 1 | 0 |
+---+---+---+
```

This skip will cost the same thing as if we were changing the previous character `""` (blank), to the prev target character (also blank)

```
row_index = 1
column_index = 1
matrix[row_index - 1][column_index - 1]
# => 0
```

### Insertion - Step

Now we add the next target letter. To change `s` to `sa` we need to perform an insertion.

```
+---+---+---+---+
|   |   | S | A |
+---+---+---+---+
|   | 0 | 1 | 2 |
+---+---+---+---+
| S | 1 | 0 |   |
+---+---+---+---+
```


Another way to look at an insertion is that it will cost the same as if we were targeting `s` instead of `sa` plus one. We can calculate the cost for an insertion by looking at the same row, previous column then adding one.

```
row_index = 1
column_index = 2
matrix[row_index][column_index - 1] + 1
# => 1
```


We continue with insertions for the rest of the row:


```
+---+---+---+---+---+---+---+---+---+---+
|   |   | S | A | T | U | R | D | A | Y |
+---+---+---+---+---+---+---+---+---+---+
|   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
+---+---+---+---+---+---+---+---+---+---+
| S | 1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
+---+---+---+---+---+---+---+---+---+---+
```

So the total cost of changing `s` into `saturday` would be `7`. Next character, let's change `su` into `sa`




#### Deletion


Intellectually we can see turning `su` into `s` would take 1 change, a deletion how would we calculate the cost for a deletion?

```
+---+---+---+
|   |   | S |
+---+---+---+
|   | 0 | 1 |
+---+---+---+
| S | 1 | 0 |
+---+---+---+
| U | 2 |   |
+---+---+---+
```


If we delete `u` then the cost of changing `su` into `s` is the same as changing `s` into `s` + 1 (to account for the deletion action). We already have this information stored in our matrix. We need to get the value of the same column but the previous row and add one to it.

```
row_index = 2
column_index = 1
matrix[row_index - 1, column_index] + 1
# => 1
```

The cost to change `su` to `s` would be 1 if we delete `u`.


## Substitution

To change `su` into `sa` we can substitute the `u` for an `a`

```
+---+---+---+---+
|   |   | S | A |
+---+---+---+---+
|   | 0 | 1 | 2 |
+---+---+---+---+
| S | 1 | 0 | 1 |
+---+---+---+---+
| U | 2 | 1 |   |
+---+---+---+---+
```

If we are substituting a character, the cost would be the same as the previous string (not including current character) plus 1. This cost is stored in the previous row and previous column.

```
row_index = 2
column_index = 3
matrix[row_index - 1][column_index - 1]
# => 1
```


## Algorithm

We can now calculate the cost for a deletion, substitution, and insertion. If we calculate all three, the best choice will be the lowest value. We can iterate over the entire matrix until we have calculated every value:


```
+---+---+---+---+---+---+---+---+---+---+
|   |   | S | A | T | U | R | D | A | Y |
+---+---+---+---+---+---+---+---+---+---+
|   | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
+---+---+---+---+---+---+---+---+---+---+
| S | 1 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
+---+---+---+---+---+---+---+---+---+---+
| U | 2 | 1 | 1 | 2 | 2 | 3 | 4 | 5 | 6 |
+---+---+---+---+---+---+---+---+---+---+
| N | 3 | 2 | 2 | 2 | 3 | 3 | 4 | 5 | 6 |
+---+---+---+---+---+---+---+---+---+---+
| D | 4 | 3 | 3 | 3 | 3 | 4 | 3 | 4 | 5 |
+---+---+---+---+---+---+---+---+---+---+
| A | 5 | 4 | 3 | 4 | 4 | 4 | 4 | 3 | 4 |
+---+---+---+---+---+---+---+---+---+---+
| Y | 6 | 5 | 4 | 4 | 5 | 5 | 5 | 4 | 3 |
+---+---+---+---+---+---+---+---+---+---+
```

To get the cost of changing any string to another string, we look at

```
string1 = "sunday"
string2 = "saturday"
matrix[string1.length][string2.length]
# => 3
```

The neat thing is we don't have to re-calculate any substrings. For example

```
string1 = "sun"
string2 = "sat"
matrix[string1.length][string2.length]
# => 2
```

