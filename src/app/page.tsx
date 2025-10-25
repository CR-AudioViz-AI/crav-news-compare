import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-5xl font-bold mb-6 bg-gradient-to-r from-conservative to-liberal bg-clip-text text-transparent">
            CRAV News Compare
          </h1>
          
          <p className="text-xl text-muted-foreground mb-8">
            Compare news coverage across conservative and liberal sources. 
            Analyze bias, track sentiment, and understand how different outlets cover the same stories.
          </p>

          <div className="grid md:grid-cols-2 gap-6 mb-12">
            <Link 
              href="/compare" 
              className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg hover:shadow-xl transition-shadow border border-gray-200 dark:border-gray-700"
            >
              <h3 className="text-2xl font-semibold mb-2">Compare News</h3>
              <p className="text-muted-foreground">
                View side-by-side comparison of how conservative and liberal sources cover today's stories
              </p>
            </Link>

            <Link 
              href="/international" 
              className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg hover:shadow-xl transition-shadow border border-gray-200 dark:border-gray-700"
            >
              <h3 className="text-2xl font-semibold mb-2">International</h3>
              <p className="text-muted-foreground">
                Explore news coverage across different countries and perspectives
              </p>
            </Link>

            <Link 
              href="/diff" 
              className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg hover:shadow-xl transition-shadow border border-gray-200 dark:border-gray-700"
            >
              <h3 className="text-2xl font-semibold mb-2">Article Diff</h3>
              <p className="text-muted-foreground">
                Sentence-level comparison highlighting differences between articles
              </p>
            </Link>

            <Link 
              href="/analytics" 
              className="p-6 bg-white dark:bg-gray-800 rounded-lg shadow-lg hover:shadow-xl transition-shadow border border-gray-200 dark:border-gray-700"
            >
              <h3 className="text-2xl font-semibold mb-2">Analytics</h3>
              <p className="text-muted-foreground">
                Track engagement, patterns, and insights from news coverage
              </p>
            </Link>
          </div>

          <div className="bg-gradient-to-r from-conservative-light to-liberal-light dark:from-conservative-dark dark:to-liberal-dark p-8 rounded-lg">
            <h2 className="text-2xl font-bold mb-4">Part of CR AudioViz AI Ecosystem</h2>
            <p className="text-muted-foreground mb-4">
              Integrated with JavariAI for intelligent pattern detection and learning. 
              Embeddable in your admin dashboard with full quota management and analytics.
            </p>
            <div className="flex gap-4 justify-center">
              <Link 
                href="/billing" 
                className="px-6 py-3 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
              >
                View Plans
              </Link>
              <Link 
                href="/developers" 
                className="px-6 py-3 bg-secondary text-secondary-foreground rounded-md hover:bg-secondary/90 transition-colors"
              >
                API Docs
              </Link>
            </div>
          </div>

          <div className="mt-12 text-sm text-muted-foreground">
            <p>Built with ❤️ for Roy Henderson & CR AudioViz AI</p>
            <p className="mt-2">
              Powered by Next.js 14, Supabase, Stripe, and OpenAI
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
