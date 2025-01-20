app.use(cors({
    origin: function (origin, callback) {
        // Allow specific frontend URL and main domain with subdomains
        const allowedOrigins = ['https://stage.vercel.app'];
        const regex = /^https:\/\/([a-z0-9-]+\.)?staging\.net$/;

        if (origin && (allowedOrigins.includes(origin) || regex.test(origin))) {
            callback(null, true); // ✅ Allow the origin
        } else {
            callback(new Error('Not allowed by CORS')); // ❌ Reject the origin
        }
    },
    credentials: true, // ✅ Allow cookies
}));
