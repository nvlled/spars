-- the inclusive range from m to n
function range(m, n)
    local t = {}
    while m <= n do
        t[#t+1] = m
        m = m + 1
    end
    return t
end

function randomInt(max, min)
    min = min or 1
    return math.floor(min + math.random()*(max-min+1))
end

-- randomly select an element from t
-- that is not equal to x
function randomSelect(t, x)
    if #t <= 1 then
        return t[1] ~= x and t[1] or nil
    end

    if #t == 2 then
        if t[1] == x then return t[2] end
        if t[2] == x then return t[1] end
    end

    -- if n is large enough, then it is very unlikely
    -- to have n iterations
    local n = #t*3
    while n > 0 do
        local i = randomInt(#t)
        if t[i] ~= x then
            return t[i]
        end
        n = n - 1 -- prevent possible infinite loop
                  -- e.g. t = {x,x,x, ...}
    end
    return nil
end

function concat(...)
    local result = {}
    local i = 1
    for _, t in ipairs{...} do
        for _, x in ipairs(t) do
            result[i] = x
            i = i + 1
        end
    end
    return result
end

-- Exchange places of
-- keys and values,
-- {k -> v } -> {v -> k}
function invertTable(t)
    local t_ = {}
    for k, v in pairs(t) do
        t_[v] = k
    end
    return t_
end

function copy(t)
    local t_ = {}
    for k, v in pairs(t) do
        t_[k] = v
    end
    return t_
end

-- Merges `t` and `defs` where
-- values in `t` takes priority.
-- Modifies `t`.
function defaults(t, defs)
    if t == nil then
        return defs
    end
    for k, v in pairs(defs) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end

function indexOf(xs, x)
    for i, y in ipairs(xs) do
        if x == y then
            return i
        end
    end
    return -1
end

-- binary shuffling algorithm
-- ^ : random index
-- {a, b, c, d, e, g}
--        ^
-- {a, b}   {d, e, g}
--  ^           ^
-- {b}      {d, g}
--  ^           ^
-- {}       {d}
--           ^
-- {}       {}
-- =>{c, a, e, b, g, d}
function randomIndices(t, len)
    function run(t, min, max, len)
        min = min or 1
        max = max or #t

        if min > max or len <= 0 then
            return {}
        end

        local i = randomInt(max, min)
        local left  = run(t, min, i-1, len-1)
        local right = run(t, i+1, max, len-1-#left)
        return concat({i}, left, right)
    end
    return run(t, nil, nil, len or #t)
end

function iter(xs, fn)
    for i, v in ipairs(xs) do
        xs[i] = fn(v, i)
    end
    return xs
end

function isTable(t) return type(t) == "table" end

-- converts a table {k1 = v1, k2 = v2, ...}
-- to {{k1, v1}, {k2, v2}, ...}
function pairList(t)
    local t_ = {}
    for k, v in pairs(t) do
        t_[#t_+1] = {k, v}
    end
    return t_
end

function when(cond, conseq, alt)
    if cond then
        return conseq
    else
        return alt
    end
end

------------------------------------------------------------

function validateTable(session)
    local table = session.table
    assert(isTable(table.header), "table requires header")
    assert(isTable(table.body), "table requires body")
    assert(#table.header >= 2, "table must have at least two columns")
    local headerLen = #table.header
    for _, row in ipairs(table.body) do
        assert(#row == headerLen, "table requires equal column size")
    end
    if session.question then
        assert(indexOf(table.header, session.question) > 0,
        "invalid question column: " .. tostring(session.question))
    end
    if session.answer then
        assert(indexOf(table.header, session.answer) > 0,
        "invalid answer column" .. tostring(session.answer))
    end
end

function formatQuestion(question, questionCol, answerCol)
    return "? " .. question
end

function formatPrompt(answerCol)
    return answerCol .. "> "
end

function formatChoices(choices)
    local s = "|  "
    for i, c in pairs(choices) do
        s = s .. "["..i..". "..c.."] "
    end
    return s
end

local Session = {
    table = nil,
    limit = -1,
    shuffle = true,
    indices = nil,
    numChoices = 3,

    answer = nil,
    question = nil,

    showChoices = true,
    showCorrect = true,
    showScore = true,
    repeatMistakes = true,
    formatQuestion = formatQuestion,
    formatPrompt = formatPrompt,
    formatChoices = formatChoices,
}
Session.__index = Session

function Session.create(o)
    o = o or {}
    setmetatable(o, Session)

    validateTable(o)
    local t = o.table
    if o.indices == nil then
        if o.shuffle then
            o.indices = randomIndices(t.body)
        else
            o.indices = range(1, #t.body)
        end
    end
    o.columns = invertTable(o.table.header)
    return o
end

function Session:columnNo(columnName)
    return self.columns[columnName]
end

function Session:getData(i, colName)
    local body = self.table.body
    return body[i][self:columnNo(colName)]
end

function Session:getRow(i)
    local header = self.table.header
    local row = copy(self.table.body[i])
    for j, v in ipairs(row) do
        local colname = header[j]
        row[colname] = v
    end
    return row
end

function Session:columnAnswer()
    return self:columnNo(self.answer)
end

function Session:columnQuestion()
    return self:columnNo(self.question)
end

function Session:getQuestionAnswer()
    local header = self.table.header
    local question, answer
    -- ensure that question header ~= answer header
    if not(self.question) and not(self.answer) then
        question = randomSelect(header)
        answer = randomSelect(header, question)
    elseif not(self.question) then
        answer = self.answer
        question = randomSelect(header, answer)
    else
        question = self.question
        answer = randomSelect(header, question)
    end
    return question, answer
end

local Context = {}
Context.__index = Context

function Context.create(o)
    setmetatable(o, Context)
    return o
end

function Context:choices()
    local choices = {}
    local session = self.session
    local table = session.table
    local numChoices = session.numChoices

    local choices = iter(randomIndices(table.body, numChoices),
    function(i)
        --return session:getData(i, session:columnAnswer())
        return session:getData(i, self.acol)
    end)
    local answer = self.answer
    local choiceno = indexOf(choices, answer)
    if choiceno <= 0 then
        choiceno = randomInt(session.numChoices)
        choices[choiceno] = answer
    end

    return choices, choiceno
end

-- if question column is not given,
--    or answer column is not given,
--  pick one at random
function Session:iter(fn)
    local i = 1
    while i <= #self.indices do
        local rowno = self.indices[i]
        local row = self:getRow(rowno)
        local qcol, acol = self:getQuestionAnswer()
        local context = Context.create{
            session = self,
            rowno = rowno,
            row = row,
            qcol = qcol,
            acol = acol,
            question = self:getData(rowno, qcol),
            answer = self:getData(rowno, acol),
        }
        local done = fn(context)
        if done then
            break
        end
        i = i + 1
    end
end

function Session:repl()
    local mistakes = {}
    local score = 0
    local total = 0

    local fn = function(context)
        local choices, choiceno = context:choices()
        print( self.formatQuestion(context.question, context.qcol, context.acol)
            .. "   "
            .. when(self.showChoices, self.formatChoices(choices), "")
        )

        local answer = ""
        while answer == "" do
            io.write(self.formatPrompt(context.acol))
            answer = io.read()
            if answer == nil then
                print()
                return true
            end
        end

        if answer == context.answer or choiceno == tonumber(answer) then
            score = score + 1
            if self.showCorrect then
                print("✓ correct")
            end
        else
            mistakes[#mistakes+1] = context.rowno
            print("✗ " .. context.answer)
            os.execute("sleep 0.5") -- teh horror
        end
        total = total + 1
    end
    self:iter(fn)

    if self.repeatMistakes then
        self.indices = mistakes
        mistakes = {}
        self:iter(fn)
    end
    if self.showScore then
        print("Your score: " .. score, "total: " .. total)
    end

    return score, total, mistakes
end

math.randomseed(os.time())

return {
    create = function(args)
        return Session.create(args)
    end,
    startRepl = function(args)
        local session = Session.create(args)
        session:repl()
    end,
    pairList = pairList,
}
