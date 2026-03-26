const express = require('express');
const path = require('path');
const app = express();
const movies = require('./data/movies.json');

app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));

// Routes
app.get('/', (req, res) => {
    const search = req.query.search;
    let filteredMovies = movies;
    if (search) {
        filteredMovies = movies.filter(m => m.title.toLowerCase().includes(search.toLowerCase()));
    }
    res.render('index', { movies: filteredMovies, search });
});

app.get('/movie/:id', (req, res) => {
    const movie = movies.find(m => m.id == req.params.id);
    if (movie) {
        res.render('movie', { movie });
    } else {
        res.send('Movie not found!');
    }
});

app.get('/login', (req, res) => {
    res.render('login');
});

app.post('/login', (req, res) => {
    const { email, password } = req.body;
    if (email && password) res.redirect('/');
    else res.send('Login failed!');
});

app.get('/signup', (req, res) => {
    res.render('signup');
});

app.post('/signup', (req, res) => {
    const { email, password } = req.body;
    if (email && password) res.redirect('/login');
    else res.send('Signup failed!');
});

app.listen(3000, () => console.log('Server running on http://localhost:3000'));